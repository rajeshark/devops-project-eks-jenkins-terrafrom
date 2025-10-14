const User = require('../models/User');
const sequelize = require('../config/database');

const seedUsers = async () => {
  try {
    await sequelize.sync({ force: false });
    console.log('Database synced for seeding');

    // No test users - database will be empty initially
    // Users can register through the application
    
    console.log('User seeding completed - database ready for user registration');
    
  } catch (error) {
    console.error('Error during user seeding:', error);
  }
};

if (require.main === module) {
  seedUsers();
}

module.exports = seedUsers;