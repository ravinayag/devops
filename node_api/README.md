# Nodejs API and Mysql Database


### A simple example : How to create RESTful API for CRUD operation using mysql database. 

1,  Create a node js related files

2,  Create the Database & table

3,  Run node service and do Add, Fetch, Edit, Delete Record using restAPI call into mysql database

#### 1 :  Create a node js related files
1a,  Have a project directory on your own, under directory create new file named : server.js
This file contains your db connection file, json format and db query for all CURD Operations.
```
$ vi server.js
var http = require("http");
var express = require('express');
var app = express();
var mysql      = require('mysql');
var bodyParser = require('body-parser');

//start mysql connection
var connection = mysql.createConnection({
  host     : 'localhost',
  user     : 'root',
  password : 'password',
  database : 'kstest'
});


connection.connect(function(err) {
  if (err) throw err
  console.log('You are now connected with mysql database...')
})

//start body-parser configuration

app.use( bodyParser.json() );       // to support JSON-encoded bodies
app.use(bodyParser.urlencoded({     // to support URL-encoded bodies
  extended: true
}));


//create app server

var server = app.listen(8000, "0.0.0.0", function () {

  var host = server.address().address
  var port = server.address().port

  console.log("Example app listening at http://%s:%s", host, port)

});


//rest api to get all learning materials
        app.get('/learningtab', function (req, res) {
                   connection.query('select * from learningtab', function (error, results, fields) {
                                  if (error) throw error;
                                  res.end(JSON.stringify(results));
                                });
        });



//rest api to get a single learning meterial data
app.get('/learningtab/:id', function (req, res) {
   connection.query('select * from learningtab where Id=?', [req.params.id], function (error, results, fields) {
          if (error) throw error;
          res.end(JSON.stringify(results));
        });
});


//rest api to create a new learning meterial record into mysql database
app.post('/learningtab', function (req, res) {
   var params  = req.body;
   console.log(params);
   connection.query('INSERT INTO learningtab SET ?', params, function (error, results, fields) {
          if (error) throw error;
          res.end(JSON.stringify(results));
        });
});

//rest api to update record into mysql database
app.put('/learningtab', function (req, res) {
   connection.query('UPDATE `learningtab` SET `Book`=?,`Author`=?,`Country`=?,`Phone`=? where `Id`=?', [req.body.Book,req.body.Author, req.body.Country, req.body.Phone, req.body.Id], function (error, results, fields) {
          if (error) throw error;
          res.end(JSON.stringify(results));
        });
});


//rest api to delete record from mysql database
app.delete('/learningtab', function (req, res) {
   console.log(req.body);
   connection.query('DELETE FROM `learningtab` WHERE `Id`=?', [req.body.Id], function (error, results, fields) {
          if (error) throw error;
          res.end('Record has been deleted!');
        });
});
```
### 1b : Create Package.json file
The package file contains all dependency package that you need to run for this service. running npm install will download all related node library to run the service.

```
$ vi package.json
{
  "name": "nodejs-restapi",
  "version": "1.0.0",
  "description": "Simple code for  nodejs to create rest call using MySQL",
  "main": "index.js",
  "scripts": {
    "start": "node ./index.js",
    "start-dev": "nodemon ./index.js"
  },
  "author": {
    "name": "Ravi",
    "email": "contact@knowledgesociety.tech",
    "url": "http://www.knowledgesociety.tech/"
  },
  "license": "MIT",
  "dependencies": {
    "body-parser": "^1.16.1",
    "express": "^4.14.1",
    "nodemon": "^2.0.1",
    "mysql": "^2.13.0"
  },
  "devDependencies": {
    "nodemon": "^2.0.1"
  }
}
```


#### 2 :  Create the Database & table manually 
Create database and table ready for access. I have created a single row for read purpose.

Login to mysqldb 
```
$ mysql -u root -p
mysql> create database test;

mysql> CREATE TABLE IF NOT EXISTS `learntab` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `Book` varchar(255) NOT NULL,
  `Author` varchar(255) NOT NULL,
  `Country` varchar(100) NOT NULL,
  `Phone` int(10) NOT NULL,
  `Created_on` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Updated_on` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


mysql> desc learntab;
+------------+--------------+------+-----+-------------------+----------------+
| Field      | Type         | Null | Key | Default           | Extra          |
+------------+--------------+------+-----+-------------------+----------------+
| Id         | int(11)      | NO   | PRI | NULL              | auto_increment |
| Book       | varchar(255) | NO   |     | NULL              |                |
| Author     | varchar(255) | NO   |     | NULL              |                |
| Country    | varchar(100) | NO   |     | NULL              |                |
| Phone      | int(10)      | NO   |     | NULL              |                |
| Created_on | datetime     | NO   |     | CURRENT_TIMESTAMP |                |
| Updated_on | datetime     | NO   |     | CURRENT_TIMESTAMP |                |
+------------+--------------+------+-----+-------------------+----------------+
7 rows in set (0.00 sec)

mysql> INSERT INTO `learntab`(Book,Author,Country,Phone) VALUES ("HarryPoter","JK Rowling","india",1234567890);
Query OK, 1 row affected (0.00 sec)

mysql> select * from learntab;
+----+------------+------------+---------+------------+---------------------+---------------------+
| Id | Book       | Author     | Country | Phone      | Created_on          | Updated_on          |
+----+------------+------------+---------+------------+---------------------+---------------------+
|  1 | HarryPoter | JK Rowling | india   | 1234567890 | 2019-12-25 15:01:50 | 2019-12-25 15:01:50 |
+----+------------+------------+---------+------------+---------------------+---------------------+
1 row in set (0.00 sec)

```
once the Database set,  move on step 3 to run the nodejs service

#### 3, under project directory,  run npm commands

$ npm install 
$ npm start 

open a browser or postman to do CURD Operataions

http://yourip:8000/learntab/

curl -x  http://yourip:8000/learntab/





