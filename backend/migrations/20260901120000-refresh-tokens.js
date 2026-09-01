'use strict';

var fs = require('fs');
var path = require('path');

var dbm;
var type;
var seed;
var Promise;

exports.setup = function (options, seedLink) {
  dbm = options.dbmigrate;
  type = dbm.dataType;
  seed = seedLink;
  Promise = options.Promise;
};

function runSqlFile (db, name) {
  var filePath = path.join(__dirname, 'sqls', name);
  return new Promise(function (resolve, reject) {
    fs.readFile(filePath, { encoding: 'utf-8' }, function (err, data) {
      if (err) return reject(err);
      resolve(data);
    });
  }).then(function (data) {
    return db.runSql(data);
  });
}

exports.up = function (db) {
  return runSqlFile(db, '20260901120000-refresh-tokens-up.sql');
};

exports.down = function (db) {
  return runSqlFile(db, '20260901120000-refresh-tokens-down.sql');
};

exports._meta = {
  version: 1
};
