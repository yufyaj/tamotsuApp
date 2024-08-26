exports.handler = async (event) => {
    console.log('Disconnect event:', event);

    // 必要に応じて接続情報をデータベースから削除
    // const connectionId = event.requestContext.connectionId;

    return {
        statusCode: 200,
        body: 'Disconnected',
    };
};