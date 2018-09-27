"Lambda handler for sending email"
import boto3
        
def lambda_handler(event, context):
    "Sends email message from lambda using SES"
    if not (('name' in event) and ('to' in event) and ('message' in event)):
        return {"code": 1, "message": "Must preovide all values"}

    if event['name'] != "" and event['to'] != "":
        name = event['name']
        toEmail = event['to']
        subject = event['subject']
        message = event['message']

        fromEmail = "nanalakshmanan.test@gmail.com"
        replyTo = fromEmail
        
        subject = "[" + name + "]" + ":" + subject 
        
        client = boto3.client('ses')
        response = client.send_email(
			Source=fromEmail,
			Destination={
				'ToAddresses': [
					toEmail,
				],
			},
			Message={
				'Subject': {
					'Data': subject,
					'Charset': 'utf8'
				},
				'Body': {
					'Text': {
						'Data': message,
						'Charset': 'utf8'
					}
				}
			}
		)
			
        print (response['MessageId'])
        return {'code': 0, 'message': 'success'}