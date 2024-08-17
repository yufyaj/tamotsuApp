const { CognitoIdentityProviderClient, GetUserCommand } = require("@aws-sdk/client-cognito-identity-provider");
const mysql = require('mysql2/promise');
const { successResponse, errorResponse } = require('response-utils');

const cognitoClient = new CognitoIdentityProviderClient({ region: process.env.MY_REGION });

exports.handler = async (event) => {
    if (event.httpMethod !== 'GET') {
        return errorResponse('Method Not Allowed', 405);
    }

    const token = event.headers.Authorization?.split(' ')[1];
    if (!token) {
        return errorResponse('Authorization token is missing', 401);
    }

    let connection;

    try {
        // トークンの有効性を確認
        await cognitoClient.send(new GetUserCommand({ AccessToken: token }));

        // クエリパラメータの取得
        const { search, page = 1, perPage = 10 } = event.queryStringParameters || {};

        // データベース接続
        connection = await mysql.createConnection({
            host: process.env.DB_HOST,
            user: process.env.DB_USER,
            password: process.env.DB_PASSWORD,
            database: process.env.DB_NAME,
            charset: 'utf8mb4'
        });

        // 検索条件の構築
        let whereClause = '';
        let params = [];
        if (search) {
            const searchTerms = search.split(' ').filter(term => term.trim() !== '');
            if (searchTerms.length > 0) {
                whereClause = 'WHERE ' + searchTerms.map(() => 
                    '(name LIKE ? OR specialties LIKE ? OR introduce LIKE ? OR qualifications LIKE ?)'
                ).join(' AND ');
                params = searchTerms.flatMap(term => [`%${term}%`, `%${term}%`, `%${term}%`, `%${term}%`]);
            }
        }

        // 総件数の取得
        const [totalResult] = await connection.execute(
            `SELECT COUNT(*) as total FROM nutritionists ${whereClause}`,
            params
        );
        const total = totalResult[0].total;

        // 栄養士一覧の取得
        const offset = (page - 1) * perPage;
        console.log(whereClause, ...params);
        const [nutritionists] = await connection.execute(
            `SELECT 
                nutritionist_id as nutritionistId, 
                name, 
                profile_image_url as imageUrl, 
                introduce, 
                JSON_UNQUOTE(specialties) as specialties, 
                (SELECT COUNT(*) FROM users WHERE selected_nutritionist_id = nutritionists.nutritionist_id) as registeredUsers,
                JSON_UNQUOTE(available_hours) as availableHours
            FROM nutritionists 
            ${whereClause}
            LIMIT ? OFFSET ?`,
            [...params, String(Number(perPage)), String(offset)]
        );

        // 結果の整形
        const formattedNutritionists = nutritionists.map(n => ({
            ...n,
            specialties: JSON.parse(n.specialties),
            availableHours: JSON.parse(n.availableHours)
        }));

        return successResponse({
            nutritionists: formattedNutritionists,
            total,
            page: Number(page),
            perPage: Number(perPage)
        });

    } catch (error) {
        console.error('Error:', error);
        if (error.name === 'NotAuthorizedException') {
            return errorResponse('Invalid or expired token', 401);
        }
        return errorResponse('An error occurred while fetching nutritionists', 500);
    } finally {
        if (connection) await connection.end();
    }
};