var chai = require('chai'),
    chai_http = require('chai-http'),
    path = require('path'),
    ship = require('../..');

var should = chai.should();

chai.use(chai_http);

global.chai = chai;
global.ship = ship;
global.should = should;
global.path = path;
global.base_path = path.join(__dirname, '../fixtures')
