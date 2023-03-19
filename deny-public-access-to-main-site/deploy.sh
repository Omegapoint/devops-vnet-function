mvn clean package -U --file java-function/pom.xml
mvn azure-functions:deploy --file java-function/pom.xml