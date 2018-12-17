ENV="http://aem-docker-training.aws-preprod.telegraph.co.uk:4502"
AUTH="admin:admin"
PACKAGE_GROUP="hub-migrated-manual"
NAME="content.zip"

curl -u ${AUTH} -X POST ${ENV}/crx/packmgr/update.jsp \
-F path=/etc/packages/${PACKAGE_GROUP}/${NAME}.zip \
-F packageName=${NAME} \
-F groupName=hub-migrated-manual \
-F filter="[ \
    FILTERS_GO_HERE
]" \
-F '_charset_=UTF-8'
