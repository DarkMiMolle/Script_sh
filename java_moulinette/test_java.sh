mvn clean install
read -p "<package.Class> : " p
mvn exec:java -Dexec.mainClass="$p"
