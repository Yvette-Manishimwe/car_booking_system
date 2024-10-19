const jwt = require('jsonwebtoken');

function authenticateToken(req, res, next) {
  const token = req.header('Authorization')?.split(' ')[1];
  if (!token) return res.status(401).json({ success: false, message: 'Access Denied' });

  jwt.verify(token, process.env.JWT_SECRET_KEY, (err, user) => {
      if (err) return res.status(403).json({ success: false, message: 'Invalid Token' });

      req.userId = user.id;
      req.category = user.category;

      // Check if the user is a driver or a passenger
      if (req.category === 'Driver') {
          req.driver_id = user.id;
      } else if (req.category === 'Passenger') {
          req.passenger_id = user.id;
      }
      console.log('Authenticated user:', req.userId, 'category:', req.category);

      next();
  });
}



module.exports = authenticateToken;
