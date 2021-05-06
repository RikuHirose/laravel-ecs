# laravel-ecs

## docker のインストール
開発環境はdocker上に構築するため、下記のリンクからインストールを行う。

### Windows
<https://docs.docker.com/toolbox/toolbox_install_windows/>

### Mac
<https://hub.docker.com/editions/community/docker-ce-desktop-mac>

## Clone xrooms
プロジェクトを`git clone`する。clone場所は以下とする。
```
cd ~
git clone https://github.com/RikuHirose/laravel-ecs.git
```

クローンした後にプロジェクトフォルダに移動し、後述の作業を行う
```
cd ~/laravel-ecs
```

## アプリケーションの立ち上げ

### dockerコンテナの起動

以下のコマンドでdockerコンテナを立ち上げる
```
make init
```

2回目以降の立ち上げの場合は以下のコマンドで実行する
```
make up
```

立ち上げたphpコンテナに入る
```
docker-compose exec app bash
```


## 実装方針
基本的にはこちらの方針に沿って実装を行う
https://zenn.dev/mpyw/articles/ce7d09eb6d8117
https://qiita.com/nunulk/items/bc7c93a3dfb43b01dfab

### UseCase をつくる際のガイドライン
- 原則的に動詞を想起させる名前にする
- 公開メソッドはひとつ
- 継承はしない
- 状態を持たない
- Service や Model に対する命令へのワークフローを構築する

### Service をつくる際のガイドライン
- 原則的には動詞を想起させる名前にする
- 状態を持たない
- 以下のいずれかに該当する
  - 外部 API （Stripe や GitHub など）や SDK をラップする
  - ファイルのインポート/エクスポートを行う
  - Excel や PDF などを操作する
  - どのモデルにも属さないまとまった処理を行う

## AWS構成図
![fargate](https://user-images.githubusercontent.com/32767218/117153274-c5ad6500-adf5-11eb-86a1-8ca532e1396b.png)

参考)AWS ソリューション構成例 - コンテナを利用した Web サービス
https://aws.amazon.com/jp/cdp/ec-container/

## インフラ構築手順
### 手作業編
- route53にてホストゾーンの作成
- tokyoとvirginiaでacm証明書を発行
=> それぞれのacm証明書のarnを控えておく

- terraformを実行するためのiam userを作成する
- 自分のPCの ~/.aws配下にprofileを設定する
`
[laravel-ecs]
aws_access_key_id = 
aws_secret_access_key = 
region = ap-northeast-1
`
- tfstateをS3バケットで管理するため、S3バケットを作成する
bucket name) laravel-ecs-production-terraform-state-bucket バージョニングの有効
参考) https://7me.nobiki.com/2020/08/21/terraform-tfstate-backend-s3/

- file upload用のs3バケットの作成

- keypairの作成
=> basion server用にec2のキーペアでlaravel-ecs.pemを作成
- 自分のPCの ~/.ssh配下にprofileを設定する
- `chmod 600 laravel-ecs.pem`


- aws systems managerのパラメータストアにて環境変数を定義する
/laravel-ecs-production/app/key
/laravel-ecs-production/db/name
/laravel-ecs-production/db/password
/laravel-ecs-production/db/username
/laravel-ecs-production/redis/name


- docker-composeしたnginxとphpのimageをECRにpushする
`export AWS_DEFAULT_PROFILE=laravel-ecs`

### terraform編
`cd terraform/`
`terraform init`
`terraform plan`
`terraform apply`

### CI/CD編
- circleciにCICD用の環境変数を指定
masterにpushされるとcircleci経由でimageとserviceの更新が行われる
AWS_ACCESS_KEY_ID
AWS_DEFAULT_REGION 
AWS_ECR_ACCOUNT_URL
AWS_REGION 
AWS_SECRET_ACCESS_KEY

### fargateのコンテナにsshする
`aws ecs execute-command --cluster laravel-ecs-production --task 265e0fb36ce6425c8d73a3dd42ec0c4f --container app --interactive --command "/bin/sh"`





