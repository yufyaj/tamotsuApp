const mysql = require('mysql2/promise');
const { successResponse, errorResponse } = require('response-utils');
const { verifyAccessToken } = require('token-handler');

exports.handler = async (event) => {
    let connection;

    try {
        console.log('debug_log_0:start');

        console.log('Connect event:', event);
        const token = event.queryStringParameters.token;
        console.log('token:', token);
        const { result, userId, nutritionistId } = await verifyAccessToken(token);
        console.log(result, userId, nutritionistId);
        if (!result) {
            return errorResponse('トークン検証に失敗しました', 401);
        }

        const connectorId = (userId !== null) ? userId : nutritionistId;
        const connectionId = event.requestContext.connectionId;
        const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    
        console.log("debug_log_1: verified token");

        // データベース接続
        connection = await mysql.createConnection({
            host: process.env.DB_HOST,
            user: process.env.DB_USER,
            password: process.env.DB_PASSWORD,
            database: process.env.DB_NAME
        });

        console.log('debug_log_2:connected db');

        // 接続情報をデータベースに保存
        await connection.execute(
            'INSERT INTO connections (connection_id, connector_id, connected_at) VALUES (?, ?, ?)',
            [connectionId, connectorId, now]
        );

        console.log('debug_log_3:inserted db');

        return successResponse({
            message: "チャット領域を作成しました"
        });
    } catch (error) {
        console.error('Error:', error);
        if (connection) await connection.rollback();

        return errorResponse('An error occurred while making chat connect', 500);
    } finally {
        if (connection) await connection.end();
    }
};