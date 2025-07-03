const crypto = require('crypto');

const generateRandomPassword = (length = 12) => {
  return crypto.randomBytes(Math.ceil(length / 2))
    .toString('hex')
    .slice(0, length);
};

const generateActivationToken = () => {
  return crypto.randomBytes(32).toString('hex');
};

module.exports = { generateRandomPassword, generateActivationToken };