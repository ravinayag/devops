var http = require("http");
var express = require('express');
var app = express();
var mysql      = require('mysql');
var bodyParser = require('body-parser');

//start mysql connection
var connection = mysql.createConnection({
  host     : 'localhost',
  user     : 'root',
  password : '',
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
   connection.query('UPDATE `learningtab` SET `Book`=?,`Address`=?,`Country`=?,`Phone`=? where `Id`=?', [req.body.Book,req.body.Address, req.body.Country, req.body.Phone, req.body.Id], function (error, results, fields) {
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
