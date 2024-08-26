const mysql = require('mysql2/promise');
const { successResponse, errorResponse } = require('response-utils');
const { verifyAccessToken } = require('token-handler');

exports.handler = async (event) => {
    if (event.httpMethod !== 'PUT') {
        return errorResponse('Method Not Allowed', 405);
    }

    console.log("debug_log_0: start");

    const token = event.headers.Authorization.split(' ')[1];
    const { result, userId } = await verifyAccessToken(token);
    if (!result || !userId) {
        return errorResponse('トークン検証に失敗しました', 401);
    }
    console.log("debug_log_1: verified token");

    let connection;

    try {
        // リクエストボディをパース
        const { nutritionistId } = JSON.parse(event.body);

        if (!nutritionistId) {
            return errorResponse('Nutritionist ID is required', 400);
        }

        // データベース接続
        connection = await mysql.createConnection({
            host: process.env.DB_HOST,
            user: process.env.DB_USER,
            password: process.env.DB_PASSWORD,
            database: process.env.DB_NAME
        });

        console.log('debug_log_3:connected db');

        // トランザクション開始
        await connection.beginTransaction();

        // 栄養士の存在確認
        const [nutritionists] = await connection.execute(
            'SELECT nutritionist_id FROM nutritionists WHERE nutritionist_id = ?',
            [nutritionistId]
        );

        console.log('debug_log_4:selected nutritionists');

        if (nutritionists.length === 0) {
            await connection.rollback();
            return errorResponse('Specified nutritionist does not exist', 404);
        }

        // ユーザーの栄養士を更新
        const updatedAt = new Date().toISOString();
        await connection.execute(
            'UPDATE users SET selected_nutritionist_id = ? WHERE user_id = ?',
            [nutritionistId, userId]
        );

        console.log('debug_log_5:updated users');

        // トランザクションをコミット
        await connection.commit();

        console.log('debug_log_6:commited');

        return successResponse({
            message: "管理栄養士を決定しました",
            updatedAt: updatedAt
        });

    } catch (error) {
        console.error('Error:', error);
        if (connection) await connection.rollback();

        if (error.name === 'NotAuthorizedException') {
            return errorResponse('Invalid or expired token', 401);
        }
        return errorResponse('An error occurred while selecting nutritionist', 500);
    } finally {
        if (connection) await connection.end();
    }
};