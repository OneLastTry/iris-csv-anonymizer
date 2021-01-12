# CSV Anonymizer Powered by InterSystems IRIS®

Tiny web application that allows you to anonymize CSV files. Based on [InterSystems IRIS®](https://www.intersystems.com/products/intersystems-iris)

**Version:** _store/intersystems/iris-community:2020.3.0.221.0_

## Application

Sample CSV where Date of Birth and Sex will remain untouched, while the rest should be anonymized.

![before](assets/before.png)

The application recognizes the header columns and allows the user to chose which ones to ignore.

![demo](assets/demo.gif)

After processing.

![after](assets/after.png)

## Setup

**Make sure you have Docker up and running before starting.**

### Option 1

Recommended in case you just want to get the application up and running.

```bash
docker run --publish 9091:1972 --publish 9092:52773 rlourenc/iris-csv-anonymizer:1.0
```

### Option 2

Recommended in case you want to play with the source code and twiki it to your taste.

Clone the repository to your desired directory

```bash
git clone https://github.com/OneLastTry/iris-csv-anonymizer.git
```

Once the repository is cloned, execute:

**Always make sure you are inside the main directory to execute docker-compose commands.**

```bash
docker-compose up
```

## Access

You can now access the application via [http://localhost:9092/appl/Anonymizer.Web.Application.zen](http://localhost:9092/appl/Anonymizer.Web.Application.zen)
