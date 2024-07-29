const AWS = require('aws-sdk');
const cognito = new AWS.CognitoIdentityServiceProvider();
const ses = new AWS.SES();

exports.handler = async (event) => {
    const { email, password, userType } = JSON.parse(event.body);
    const clientId = process.env.COGNITO_USER_POOL_CLIENT_ID;

    // 入力バリデーション
    if (!email || !password || !userType) {
        return response(400, { message: '必須フィールドが不足しています' });
    }
    
    // カスタム検証コードの生成
    const verificationCode = Math.random().toString(36).substring(2, 8);

    const params = {
        ClientId: clientId,
        Username: email,
        Password: password,
        UserAttributes: [
            {
                Name: 'email',
                Value: email
            }, {
                Name: 'custom:verificationCode', 
                Value: verificationCode
            }
        ]
    };

    try {
        const result = await cognito.signUp(params).promise();
        const userId = result.UserSub;
        console.log('User signed up successfully:', result);
    } catch (error) {
        console.error('Error signing up user:', error);
        return response(500, JSON.stringify({ message: 'Error signing up user', error: error.message }));
    }

    try {
        // DynamoDBにユーザー情報を保存
        const dynamoParams = {
            TableName: 'Users',
            Item: {
              PK: `USER#${userId}`,
              SK: 'METADATA#',
              GSI1PK: 'TYPE#USER',
              GSI1SK: `USER#${userId}`,
              GSI2PK: `EMAIL#${email}`,
              GSI2SK: `USER#${userId}`,
              Type: 'USER',
              Data: {
                email: email,
                userType: userType,
                created_at: new Date().toISOString(),
                isVerified: false
              }
            }
        };
    } catch (error) {
        await dynamodb.put(dynamoParams).promise();
    }

    try{
        // カスタム検証メールの送信
        await ses.sendEmail({
            Destination: { ToAddresses: [email] },
            Message: {
                Body: { Text: { Data: `TAMOTSUへご登録頂きありがとうございます。\nhttps://api.tamotsu-app.com/user/confirm?email=${email}&code=${verificationCode}` } },
                Subject: { Data: 'TAMOTSUへご登録ありがとうございます' }
            },
            Source: process.env.FROM_EMAIL_ADDRESS
        }).promise();

        return response(200, JSON.stringify({ message: 'User signed up successfully'});
    } catch (error) {
        console.error('Error send mail:', error);
        return response(500, { message: 'Error send mail', error: error.message });
    }
};

function response(statusCode, body) {
    return {
      statusCode: statusCode,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*', // CORSの設定 本番環境では特定のオリジンに制限することをお勧めします
        'Access-Control-Allow-Credentials': true,
        "Access-Control-Allow-Headers": "Content-Type",
},
      body: JSON.stringify(body)
    };
  }
