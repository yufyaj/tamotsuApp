const mysql = require('mysql2/promise');
const { successResponse, errorResponse } = require('response-utils');
const { verifyAccessToken } = require('token-handler');

exports.handler = async (event) => {
    if (event.httpMethod !== 'PUT') {
        return errorResponse('Method Not Allowed', 405);
    }

    console.log('debug_log_0:start');

    const token = event.headers.Authorization.split(' ')[1];
    const { result, userId } = await verifyAccessToken(token);
    if (!result || !userId) {
        return errorResponse('トークン検証に失敗しました', 401);
    }

    console.log("debug_log_1: verified token");

    var connection = null;

    try{
        const { nutritionistId } = JSON.parse(event.body);

        // データベース接続
        connection = await mysql.createConnection({
            host: process.env.DB_HOST,
            user: process.env.DB_USER,
            password: process.env.DB_PASSWORD,
            database: process.env.DB_NAME
        });

        console.log('debug_log_2:connected db');

        // チャット領域を作成
        const [sequenceResult] = await connection.execute('SELECT get_next_sequence("chat_id_seq") AS next_val');
        const chatId = `C${String(sequenceResult[0].next_val).padStart(7, '0')}`;

        console.log('debug_log_4:created id');

        const now = new Date().toISOString().slice(0, 19).replace('T', ' ');

        await connection.execute(
            'INSERT INTO chats (chat_id, user_id, nutritionist_id, status, created_at) VALUES (?, ?, ?, ?, ?)',
            [chatId, userId, nutritionistId, 'active', now]
        );

        console.log('debug_log_5:created chat');

        // トランザクションをコミット
        await connection.commit();

        return successResponse({
            message: "チャット領域を作成しました"
        });

    } catch (error) {
        console.error('Error:', error);
        if (connection) await connection.rollback();

        return errorResponse('An error occurred while making chat connect', 500);
    } finally {
        if (connection !== null) await connection.end();
    }
}