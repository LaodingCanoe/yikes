const multer = require('multer'); // Добавьте эту строку
const express = require('express');
const sql = require('mssql');
const cors = require('cors');
const bodyParser = require('body-parser');
const path = require('path');
const app = express();
const imageDirectory = 'W:/Lerning/Diplom/product_image/';
const addImageDirectory = 'W:/Lerning/Diplom/add_image/';
const categoriesImageDirectory = 'W:/Lerning/Diplom/categories_image/';
const userAvatarDirectory = 'W:/Lerning/Diplom/userAvatar/';
const serverIp = '192.168.0.103'; // Измените на нужный IP
const port = 3000;
const nodemailer = require('nodemailer');
const bcrypt = require('bcrypt');

//const dbConfig = require('./db_config');
//const { TableNames, Бренды, Гендер, Заказы } = require('./tables');

app.use(cors()); // обязательно добавьте CORS для доступа к API из других доменов
app.use(bodyParser.json()); // используем body-parser для работы с JSON запросами

const dbConfig = {
    user: 'UserYaikes',
    password: 'qwerty1',
    server: serverIp, // Использование переменной для IP
    port: 49172,
    database: 'Yikes',
    options: {
        encrypt: false,
        enableArithAbort: true,
    }, 
        
};

app.get('/products', async (req, res) => { 
    const gendrCode = req.query.gendrCode;
    const categoryId = req.query.categoryId;
    const subcategory = req.query.subcategory;
    const hashtag = req.query.hashtag;
    const obraz = req.query.obraz;
    const search = req.query.search;

    try {
        let pool = await sql.connect(dbConfig);
        let query = `
            SELECT 
                t.ТоварID,
                t.Название AS Название,
                Артикул,
                c.Название AS Цвет,
                c.КодЦвета,
                Цена,
                k.Название AS Категория,
                p.Название AS Подкатегория,
                b.Название AS Бренд,
                g.Название AS Гендр,
                МагазинID,
                КоллекцияID,
                t.Описание,
                t.ДатаДобавления,                
				o.ID AS ОбразID
            FROM Товары AS t
            JOIN Цвета AS c ON t.ЦветID = c.ID
            JOIN Подкатегория AS p ON t.ПодкатегорияID = p.ID
            JOIN Категория AS k ON p.КатегорияID = k.ID
            JOIN Бренды AS b ON t.БрендID = b.ID
            JOIN Гендер AS g ON t.ГендерID = g.ID            
			LEFT JOIN Образы AS o ON t.ТоварID = o.ТоварID
        `;
        if (hashtag) {
            query += ` 
            LEFT JOIN ТоварыХештеги AS th ON t.ТоварID = th.ТовараID
            LEFT JOIN Хештеги AS h ON th.ХештегID = h.ID
            `;
        }
        query += ` WHERE 1=1`;
        if (hashtag) {
            query += ` 
            AND h.Название = @hashtag`;
        }
        if (obraz && obraz !== 'all') {
            query += ` AND o.ID = @obraz`;
        }
        // Добавление условий фильтрации
        if (gendrCode && gendrCode !== 'all') {
            query += ` AND g.ID = @gendrCode`;
        }
        if (categoryId && categoryId !== 'all') {
            query += ` AND k.ID = @categoryId`;
        }
        if (subcategory && subcategory !== 'all') {
            query += ` AND p.ID = @subcategory`;
        }
        if (search) {
            query += ` AND (
                t.Название LIKE @search
                OR t.Артикул LIKE @search
                OR k.Название LIKE @search
                OR p.Название LIKE @search
                OR EXISTS (
                    SELECT 1 FROM ТоварыХештеги th 
                    JOIN Хештеги h ON th.ХештегID = h.ID 
                    WHERE th.ТовараID = t.ТоварID AND h.Название LIKE @search
                )
            )`;
        }

        query += ` ORDER BY t.ДатаДобавления DESC`;

        const request = pool.request();

        // Передача параметров
        if (gendrCode && gendrCode !== 'all') {
            request.input('gendrCode', sql.Int, gendrCode);
        }
        if (subcategory && subcategory !== 'all') {
            request.input('subcategory', sql.Int, subcategory);
        }
        if (categoryId && categoryId !== 'all') {
            request.input('categoryId', sql.Int, categoryId);
        }
        if (hashtag) {
            request.input('hashtag', sql.NVarChar, hashtag);
        }
        if (obraz) {
            request.input('obraz', sql.Int, obraz);
        }
        if (search) {
            request.input('search', sql.NVarChar, `%${search}%`);
        }

        const result = await request.query(query);
        res.json(result.recordset);
    } catch (error) {
        res.status(500).send(error.message);
    }
});


app.use('/images', express.static(imageDirectory));
app.get('/productImages', async (req, res) => {
    const productId = req.query.productId;

    try {
        let pool = await sql.connect(dbConfig);
        const result = await pool.request()
            .input('ProductId', sql.Int, productId)
            .query(`
                SELECT ПутьФото
                FROM ФотоТовара AS f
                JOIN ТоварФото AS t ON f.ID = t.ФотоID
                WHERE t.ТоварID = @ProductId
            `);

        console.log('Product images:', result.recordset);

        const images = result.recordset.map(item => {
            return {
                
                Путь: `http://${serverIp}:${port}/images/${item.ПутьФото}`
            };
        });

        res.json(images);
    } catch (error) {
        console.error('Error fetching product images:', error);
        res.status(500).send(error.message);
    }
});

app.use('/addimages', express.static(addImageDirectory));
app.get('/addImages', async (req, res) => {
    const gendrCode = req.query.gendrCode;
    try {
        let pool = await sql.connect(dbConfig);
        const result = await pool.request().input('gendrCode', sql.Int, gendrCode)
            .query(`SELECT ID,ПутьФото
                    FROM РекламныеФото
                    WHERE ГендрID = @gendrCode`);

        console.log('Add images:', result.recordset);

        const images = result.recordset.map(item => {
            return {
                Путь: `http://${serverIp}:${port}/addimages/${item.ПутьФото}`
            };
        });

        res.json(images);
    } catch (error) {
        console.error('Error fetching product images:', error);
        res.status(500).send(error.message);
    }
});  

app.use('/categoriesimages', express.static(categoriesImageDirectory));
app.get('/categories', async (req, res) => {
    const gendrCode = req.query.gendrCode;
    try {
        let pool = await sql.connect(dbConfig);
        const result = await pool.request().input('gendrCode', sql.Int, gendrCode)
            .query(`SELECT ФотоКатегории.ID,ПутьФото,Категория.Название, Категория.ID AS КатегорияID  
                    FROM ФотоКатегории
                    JOIN Категория ON Категория.ID = ФотоКатегории.КатегорияID
                    WHERE ГендрID = @gendrCode`);

        console.log('categories images:', result.recordset);

        const images = result.recordset.map(item => {
            return {
                ID: item.КатегорияID,
                ПутьФото: `http://${serverIp}:${port}/categoriesimages/${item.ПутьФото}`,
                Название: item.Название
            };
        });
        res.json(images);
    } catch (error) {
        console.error('Error fetching product images:', error);
        res.status(500).send(error.message);
    }
}); 


app.get('/product-sizes', async (req, res) => {
    const productId = req.query.productId; // Получение параметра из запроса
    if (!productId) {
        return res.status(400).json({ error: 'ProductId is required' });
    }

    try {
        let pool = await sql.connect(dbConfig);
        const result = await pool
            .request()
            .input('ProductId', sql.Int, productId) // Передаем параметр
            .query(`
                SELECT t.ТоварID, r.ID AS РазмерID, Название, Размер, КоличествоНаСкладе
                FROM Товары AS t
                JOIN ТоварРазмер AS tr ON t.ТоварID = tr.ТоварID
                JOIN Размер AS r ON tr.РазмерID = r.ID
                WHERE t.ТоварID = @ProductId
            `);

        // Возвращаем результат запроса в формате JSON
        res.json(result.recordset);
    } catch (error) {
        console.error('Error fetching product sizes:', error);
        res.status(500).send(error.message);
    }
});


app.use(cors());
app.use(bodyParser.json());
app.use('/uploads', express.static(userAvatarDirectory));

// Настройка multer для загрузки аватаров


// Настройка отправки email
const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: 'yikesshoping@gmail.com',
        pass: 'yikess2000',
    },
});

// Настройка multer для загрузки аватаров с поддержкой webp
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, userAvatarDirectory); // Используем переменную для указания папки
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, uniqueSuffix + path.extname(file.originalname)); // Сохраняем оригинальное расширение
    },
});

const upload = multer({
    storage: storage,
    limits: { fileSize: 5 * 1024 * 1024 }, // Максимальный размер файла 5MB
    fileFilter: (req, file, cb) => {
        
            cb(null, true);
        
    },
});


const secretKey = 'MySuperSecretKey123!';  // Use a secure, unique key for production

// Настройка OAuth2
const { OAuth2Client } = require('google-auth-library');
const jwt = require('jsonwebtoken');

const CLIENT_ID = '988083805696-mdbm9be5cdm4ssb7ut33f1rhq1dvpkmd.apps.googleusercontent.com';

const REFRESH_TOKEN = '1//04lE7oxaix9Q0CgYIARAAGAQSNwF-L9IrTy9k3lDUZb9haA4_7ccjvRDDz7juRX106QWoX51Nz_CatmdjIyqu2BdW-4e7qU-HEt4';

// Создаем OAuth2 клиент
const oauth2Client = new OAuth2Client(CLIENT_ID, CLIENT_SECRET, REDIRECT_URI);
oauth2Client.setCredentials({ refresh_token: REFRESH_TOKEN });

app.post('/register', upload.single('avatar'), async (req, res) => {
    const { email, password, name, firstname, patranomic, add, isCorectEmail } = req.body;
    const avatar = req.file ? req.file.filename : null; // Сохраняем только название файла

    try {
        let pool = await sql.connect(dbConfig);
        const registdate = new Date(); // Текущая дата
        const role = 1; // Роль по умолчанию

        // Начинаем транзакцию
        const transaction = new sql.Transaction(pool);

        await transaction.begin();

        try {
            // Добавление пользователя и получение его ID
            const userResult = await transaction.request()
                .input('email', sql.VarChar, email)
                .input('password', sql.VarChar, password)
                .input('name', sql.VarChar, name)
                .input('firstname', sql.VarChar, firstname)
                .input('patranomic', sql.VarChar, patranomic)
                .input('add', sql.Bit, add)
                .input('isCorectEmail', sql.Bit, isCorectEmail) // Email не подтвержден
                .input('registdate', sql.DateTime, registdate) // Записываем текущую дату
                .input('role', sql.Int, role) // Роль по умолчанию
                .input('avatar', sql.VarChar, avatar) // Передаем только имя файла (или null, если нет файла)
                .query(`
                    INSERT INTO Пользователи 
                    (Email, ПарольХеш, Фамилия, Имя, Отчество, ДатаРегистрации, РольID, ПодтверждениеEmail, РекламнаяРассылка, Аватар) 
                    OUTPUT INSERTED.ID AS ПользовательID
                    VALUES 
                    (@email, @password, @firstname, @name, @patranomic, @registdate, @role, @isCorectEmail, @add, @avatar);
                `);

            const userId = userResult.recordset[0].ПользовательID;

            // Запись ID пользователя и пароля в таблицу СтарыеПароли
            await transaction.request()
                .input('userId', sql.Int, userId)
                .input('password', sql.VarChar, password)
                .query(`
                    INSERT INTO СтарыеПароли (ПользовательID, ПарольХеш)
                    VALUES (@userId, @password);
                `);

            // Подтверждаем транзакцию
            await transaction.commit();

            res.status(201).send({
                message: 'Регистрация успешна. Теперь вы можете подтвердить свою почту.',
                avatar
            });
        } catch (innerError) {
            await transaction.rollback();
            throw innerError;
        }
    } catch (error) {
        res.status(500).send({ error: error.message });
    }
});




// Send confirmation email route
app.post('/send-confirmation-email', async (req, res) => {
    const { email, firstname, name } = req.body;

    try {
        // Генерация токена для подтверждения email
        const emailToken = jwt.sign({ email }, secretKey, { expiresIn: '1h' });

        // URL подтверждения
        const confirmationUrl = `http://${serverIp}:${port}/confirm-email?token=${emailToken}`;

        // Получение токена доступа для Gmail
        const accessToken = await oauth2Client.getAccessToken();

        // Настройка транспорта для Nodemailer
        const transporter = nodemailer.createTransport({
            service: 'Gmail',
            auth: {
                type: 'OAuth2',
                user: 'yikesshoping@gmail.com',
                clientId: CLIENT_ID,
                clientSecret: CLIENT_SECRET,
                refreshToken: REFRESH_TOKEN,
                accessToken: accessToken.token,
            },
        });

        const mailOptions = {
            from: 'no-reply@example.com',
            to: email,
            subject: 'Подтверждение регистрации',
            html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #ddd; border-radius: 10px; text-align: center;">
                    <h1 style="color: #333;">Добро пожаловать, ${firstname} ${name}!</h1>
                    <p style="color: #555; font-size: 16px;">Вы успешно зарегистрировались в Yikes. Пожалуйста, подтвердите вашу почту, чтобы завершить регистрацию.</p>
                    <a href="${confirmationUrl}" style="display: inline-block; padding: 12px 24px; margin-top: 15px; background-color: #333333; color: #ffffff; text-decoration: none; font-size: 16px; border-radius: 5px;">Подтвердить Email</a>
                    <p style="margin-top: 20px; font-size: 12px; color: #888;">Если вы не регистрировались в приложении, просто проигнорируйте письмо и удалите его.</p>
                </div>
            `,
        };
        

        // Отправка email
        await transporter.sendMail(mailOptions);

        res.status(200).send({ message: 'Письмо для подтверждения отправлено на вашу почту.' });
    } catch (error) {
        res.status(500).send({ error: error.message });
    }
});




// Маршрут для подтверждения email
app.get('/confirm-email', async (req, res) => {
    const { token } = req.query;

    try {
        // Проверка токена
        const decoded = jwt.verify(token, secretKey);
        const email = decoded.email;

        // Обновление статуса подтверждения email в базе данных
        let pool = await sql.connect(dbConfig);
        await pool.request()
            .input('email', sql.VarChar, email)
            .query(`
                UPDATE Пользователи
                SET ПодтверждениеEmail = 1
                WHERE Email = @email
            `);

        res.send({ message: 'Email успешно подтвержден!' });
    } catch (error) {
        res.status(400).send({ message: 'Неверный или истекший токен.' });
    }
});

app.post('/login', async (req, res) => {
    const { email, password } = req.body;

    try {
        let pool = await sql.connect(dbConfig);
        const result = await pool.request()
            .input('email', sql.VarChar, email)
            .query(`SELECT ID, Email, ПарольХеш, Аватар, Фамилия, Имя, ПодтверждениеEmail 
                    FROM Пользователи WHERE Email = @email`);

        if (result.recordset.length === 0) {
            return res.status(404).send({ message: 'Данный пользователь не существует' });
        }

        const user = result.recordset[0];

        // Проверка пароля с использованием bcrypt
        const isPasswordValid = await bcrypt.compare(password, user.ПарольХеш);

        if (!isPasswordValid) {
            return res.status(401).send({ message: 'Неверный email или пароль' });
        }

        // Генерация токена
        const token = jwt.sign({ id: user.ID, email }, secretKey, { expiresIn: '1h' });
        const avatarUrl = user.Аватар ? `http://${serverIp}:${port}/uploads/${user.Аватар}` : null;
        
        console.log('user:', res.recordset);        

        res.send({
            token,
            id: user.ID,
            email: user.Email,
            avatar: avatarUrl,
            surname: user.Фамилия,
            name: user.Имя,
            emailConfirmation: user.ПодтверждениеEmail,
        });
    } catch (error) {
        res.status(500).send({ message: 'Ошибка сервера', error: error.message });
    }
});



// Сброс пароля: Запрос на сброс
app.post('/forgot-password', async (req, res) => {
    const { email } = req.body;

    try {
        const token = jwt.sign({ email }, secretKey, { expiresIn: '15m' });
        const resetLink = `http://${serverIp}:${port}/reset-password?token=${token}`;

        await transporter.sendMail({
            from: 'yikesshoping@gmail.com',
            to: email,
            subject: 'Сброс пароля',
            text: `Для сброса пароля перейдите по ссылке: ${resetLink}`,
        });

        res.send({ message: 'Ссылка для сброса пароля отправлена на email' });
    } catch (error) {
        res.status(500).send(error.message);
    }
});

// Сброс пароля: Установка нового пароля
app.post('/reset-password', async (req, res) => {
    const { token, newPassword } = req.body;

    try {
        const decoded = jwt.verify(token, secretKey); // Расшифровка токена
        const hashedPassword = await bcrypt.hash(newPassword, 10); // Хэширование нового пароля

        let pool = await sql.connect(dbConfig);
        await pool.request()
            .input('email', sql.VarChar, decoded.email)
            .input('password', sql.VarChar, hashedPassword)
            .query(`UPDATE Пользователи SET ПарольХеш = @password WHERE Email = @email`);

        res.send({ message: 'Пароль успешно обновлён' });
    } catch (error) {
        console.error('Ошибка сброса пароля:', error.message);
        res.status(500).send({ message: 'Не удалось сбросить пароль', error: error.message });
    }
});


app.post('/addToCart', async (req, res) => {
    const { productId, sizeId, userId, productSizeId } = req.body;
    //const productSizeId = req.query.productSizeId;

    try {
        let pool = await sql.connect(dbConfig);
        if (productSizeId == null)
        {
            const result = await pool.request()
            .input('userId', sql.Int, userId)
            .input('productId', sql.Int, productId)
            .input('sizeId', sql.Int, sizeId)
            .query(`
                INSERT INTO Корзина (ПользовательID, ТоварID, Количество, ДатаДобавления)
                VALUES (@userId,  (SELECT ID FROM ТоварРазмер WHERE ТоварID = @productId AND РазмерID = @sizeId), 1, GETDATE())
            `);

        if (result.rowsAffected[0] > 0) {
            res.json({ success: true, message: 'Товар успешно добавлен в корзину' });
        } else {
            res.status(400).json({ success: false, message: 'Не удалось добавить товар в корзину' });
        }
        }
        else{
            const result = await pool.request()
            .input('productSizeId', sql.Int, productSizeId)
            .query(`
                INSERT INTO Корзина (ПользовательID, ТоварID, Количество, ДатаДобавления)
                VALUES (@userId,   @productSizeId, 1, GETDATE())
            `);

        if (result.rowsAffected[0] > 0) {
            res.json({ success: true, message: 'Товар успешно добавлен в корзину' });
        } else {
            res.status(400).json({ success: false, message: 'Не удалось добавить товар в корзину' });
        }
        }
        
    } catch (error) {
        console.error('Ошибка добавления в корзину:', error);
        res.status(500).json({ success: false, message: 'Произошла ошибка при добавлении в корзину', error: error.message });
    }
});

app.post('/cart', async (req, res) => { 
    const { product_size, userId, productID, sizeID } = req.body; // Читаем из body

    try {
        let pool = await sql.connect(dbConfig);
        let query = `
            SELECT tr.ID AS ТоварРазмерID, t.ТоварID AS ТоварID, t.Название, t.Цена, c.Название AS Цвет, c.КодЦвета, 
            r.Размер, k.Количество, k.ДатаДобавления
            FROM ТоварРазмер AS tr
            JOIN Размер AS r ON tr.РазмерID = r.ID
            JOIN Товары AS t ON tr.ТоварID = t.ТоварID
            JOIN Цвета AS c ON t.ЦветID = c.ID
            LEFT JOIN Корзина AS k ON tr.ID = k.ТоварID
            WHERE 1=1
        `;

        if (userId && userId !== 'all') {
            query += ` AND k.ПользовательID = @userId`;
        }
        if (product_size && product_size !== 'all') {
            query += ` AND tr.ID = @product_size`;
        }
        if ((productID && productID != 'all') && (sizeID && sizeID != 'all')) {
            query += ` AND t.ТоварID = @productID AND r.ID = @sizeID`;
        }

        const request = pool.request();

        if (userId && userId !== 'all') {
            request.input('userId', sql.Int, userId);
        }
        if (product_size && product_size !== 'all') {
            request.input('product_size', sql.Int, product_size);
        }
        if ((productID && productID != 'all') && (sizeID && sizeID != 'all')) {
            request.input('productID', sql.Int, productID);
            request.input('sizeID', sql.Int, sizeID);
        }

        const result = await request.query(query);
        res.json(result.recordset);
    } catch (error) {
        res.status(500).send(error.message);
    }
});

app.delete('/delete-cart', async (req, res) => {
    const { product_sizeID, productID, sizeID, userID } = req.body;

    try {
        let pool = await sql.connect(dbConfig);
        let query = `DELETE FROM Корзина WHERE ПользовательID = @userID`;
        const request = pool.request();
        request.input('userID', sql.Int, userID);

        if (product_sizeID) {
            query += ` AND ТоварID = @product_sizeID`;
            request.input('product_sizeID', sql.Int, product_sizeID);
        } else if (productID && sizeID) {
            query += ` AND ТоварID = (SELECT ID FROM ТоварРазмер WHERE ТоварID = @productID AND РазмерID = @sizeID)`;
            request.input('productID', sql.Int, productID);
            request.input('sizeID', sql.Int, sizeID);
        }

        const result = await request.query(query);
        console.log('Executing DELETE query:', query);
        console.log('Rows affected:', result.rowsAffected);

        res.json({ success: true, data: result.rowsAffected });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});


app.post('/update-cart', async (req, res) => { 
    const { product_sizeID, productID, sizeID, userID, plus } = req.body;

    try {
        let pool = await sql.connect(dbConfig);
        let query = `UPDATE Корзина SET Количество = Количество ${plus === 'true' ? '+ 1' : '- 1'} WHERE ПользовательID = @userID`;
        
        const request = pool.request();
        request.input('userID', sql.Int, userID);

        if (product_sizeID) {
            query += ` AND ТоварID = @product_sizeID`;
            request.input('product_sizeID', sql.Int, product_sizeID);
        } else if (productID && sizeID) {
            query += ` AND ТоварID = (SELECT ID FROM ТоварРазмер WHERE ТоварID = @productID AND РазмерID = @sizeID)`;
            request.input('productID', sql.Int, productID);
            request.input('sizeID', sql.Int, sizeID);
        }

        const result = await request.query(query);
        console.log('Executing UPDATE query:', query, productID, userID);
        console.log('Rows affected:', result.rowsAffected);

        res.json({ success: true, data: result.rowsAffected });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});


app.get('/product', async (req, res) => {
    const article = req.query.article; // Получение параметра из запроса
    if (!article) {
        return res.status(400).json({ error: 'article is required' });
    }

    try {
        let pool = await sql.connect(dbConfig);
        const result = await pool
            .request()
            .input('article', sql.NVarChar, article) // Передаем параметр
            .query(`
                SELECT 
                    t.ТоварID,
                    t.Название AS Название,
                    Артикул,
                    c.Название AS Цвет,
                    c.КодЦвета,
                    Цена,
                    k.Название AS Категория,
                    k.ID AS КатегорияID,
                    p.Название AS Подкатегория,
                    b.Название AS Бренд,
                    g.Название AS Гендр,
					g.ID AS ГендрID,
                    МагазинID,
                    КоллекцияID,
                    t.Описание,
                    Размер,
	                r.ID AS РазмерID,
                    t.ДатаДобавления,
                    h.Название AS Хештег,
                    h.ID AS ХештегID,                
				    O.ID AS ОбразID
                FROM Товары AS t
                JOIN Цвета AS c ON t.ЦветID = c.ID
                JOIN Подкатегория AS p ON t.ПодкатегорияID = p.ID
                JOIN Категория AS k ON p.КатегорияID = k.ID
                JOIN Бренды AS b ON t.БрендID = b.ID
                JOIN Гендер AS g ON t.ГендерID = g.ID
                FULL JOIN ТоварыХештеги AS th ON t.ТоварID = th.ТовараID
                FULL JOIN Хештеги AS h ON th.ХештегID = h.ID
                FULL JOIN ТоварРазмер AS tr ON t.ТоварID = tr.ТоварID
                FULL JOIN Размер AS r ON r.ID = tr.РазмерID
			    LEFT JOIN Образы AS o ON t.ТоварID = o.ТоварID
                WHERE Артикул=@article
            `);

        // Возвращаем результат запроса в формате JSON
        res.json(result.recordset);
    } catch (error) {
        console.error('Error fetching product:', error);
        res.status(500).send(error.message);
    }
});

app.get('/sizesByColor', async (req, res) => {
    const article = req.query.article?.trim();
    const colorCode ='#'+ req.query.colorCode?.trim();
    if (!article) {
        return res.status(400).json({ error: 'article is required' });
    }
    if (!colorCode) {
        return res.status(400).json({ error: 'colorCode is required', colorCode, article });
    }

    try {
        let pool = await sql.connect(dbConfig);
        const result = await pool
            .request()
            .input('article', sql.NVarChar, article) // Передаем параметр
            .input('colorCode', sql.NVarChar, colorCode)
            .query(`
                SELECT 
                    t.ТоварID,                    
                    Артикул,
                    c.Название AS Цвет,
                    c.КодЦвета,                   
                    Размер,
                    r.ID AS РазмерID
                FROM Товары AS t
                FULL JOIN Цвета AS c ON t.ЦветID = c.ID                
                FULL JOIN ТоварРазмер AS tr ON t.ТоварID = tr.ТоварID
                FULL JOIN Размер AS r ON r.ID = tr.РазмерID
                WHERE Артикул=@article AND КодЦвета=@colorCode
            `);

        // Возвращаем результат запроса в формате JSON
        res.json(result.recordset);
    } catch (error) {
        console.error('Error fetching product:', error);
        res.status(500).send(error.message);
    }
});


app.listen(port, () => {
    console.log(`Server running on port ${port}`);
});

//module.exports = { poolPromise, TableNames, Бренды, Гендер, Заказы };
