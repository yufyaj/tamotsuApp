const mysql = require('mysql2/promise');
const { successResponse, errorResponse } = require('response-utils');
const { verifyAccessToken } = require('token-handler');

exports.handler = async (event) => {
    if (event.httpMethod !== 'GET') {
        return errorResponse('Method Not Allowed', 405);
    }

    console.log('debug_log_0:start');

    const token = event.headers.Authorization.split(' ')[1];
    const { result, userId, nutritionistId } = await verifyAccessToken(token);
    if (!result) {
        return errorResponse('トークン検証に失敗しました', 401);
    }

    console.log("debug_log_1: verified token");

    var connection = null;

    try {
        // データベース接続
        connection = await mysql.createConnection({
            host: process.env.DB_HOST,
            user: process.env.DB_USER,
            password: process.env.DB_PASSWORD,
            database: process.env.DB_NAME
        });

        console.log('debug_log_2:connected db');

        if (userId !== null) {
            // ユーザーが参加しているチャットIDを取得
            const [rows] = await connection.execute(
                "SELECT chats.chat_id AS chat_id, chats.nutritionist_id AS receiver_id, nutritionists.name AS receiver_name, nutritionists.profile_image_url AS receiver_profile_image_url " + 
                "FROM   chats INNER JOIN nutritionists on chats.nutritionist_id = nutritionists.nutritionist_id " +
                "WHERE  user_id = ? AND status = 'active'",
                [userId]
            );

            console.log('debug_log_3:fetched chat ids');

            // チャット詳細をレスポンスとして返す
            return successResponse({
                chats: rows
            });
        } else if (nutritionistId !== null) {
            // 管理栄養士が参加しているチャットIDを取得
            const [rows] = await connection.execute(
                "SELECT chats.chat_id AS chat_id, chats.user_id AS receiver_id, users.name AS receiver_name, users.profile_image_url AS receiver_profile_image_url " + 
                "FROM   chats INNER JOIN users on chats.user_id = users.user_id " +
                "WHERE  nutritionistId = ? AND status = 'active'",
                [nutritionistId]
            );

            console.log('debug_log_3:fetched chat ids');

            // チャット詳細をレスポンスとして返す
            return successResponse({
                chats: rows
            });
        }

        return errorResponse('トークン検証に失敗しました', 401);

    } catch (error) {
        console.error('Error:', error);
        return errorResponse('An error occurred while fetching chat IDs', 500);
    } finally {
        if (connection !== null) await connection.end();
    }
}