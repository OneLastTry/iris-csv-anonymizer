# CSV Anonymizer Powered by InterSystems IRIS®

Tiny application that allows you to anonymize CSV files. Based on InterSystems IRIS®

**Version:** _store/intersystems/iris-community:2020.3.0.221.0_

**Make sure you have Docker up and running before starting.**

## Setup

### Option 1

Clone the repository to your desired directory

```bash
git clone https://github.com/OneLastTry/iris-csv-anonymizer.git
```

Once the repository is cloned, execute:

**Always make sure you are inside the main directory to execute docker-compose commands.**

```bash
docker-compose up
```

### Option 2

```bash
docker run --publish 9091:1972 --publish 9092:52773 rlourenc/iris-csv-anonymizer:1.0
```

## Access

You can now access the application via http://localhost:9092/appl/Anonymizer.Web.Application.zen