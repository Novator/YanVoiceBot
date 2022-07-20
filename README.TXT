
=== Telegram bot for speech recognition by Yandex SpeechKit

To use bot you need:
1) Install Ruby
2) Install telegram-bot-ruby:

  gem install telegram-bot-ruby

3) Register your bot in telegram via @BotFather
4) Write your teleram bot token to file "token.txt"
5) Register on Yandex Cloud and activate catalog
6) Get IAM-token (https://cloud.yandex.ru/docs/iam/operations/iam-token/create)
and write it to file "yan_iam.txt"
7) Get FolderID (https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id)
and write it to file "yan_folder.txt"
8) Run Ruby script like this:

  ./yanvoicebot.sh

Bot must start and begin to work.
Ask your questions to: robux@mail.ru

