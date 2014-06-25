var chai = require('chai'),
    chai_promise = require('chai-as-promised'),
    chai_sinon = require('sinon-chai')
    path = require('path'),
    sinon = require('sinon'),
    Ship = require('../..');

var should = chai.should();
chai.use(chai_promise);
chai.use(chai_sinon);

global.chai = chai;
global.Ship = Ship;
global.should = should;
global.sinon = sinon;
global._path = path.join(__dirname, '../fixtures');
