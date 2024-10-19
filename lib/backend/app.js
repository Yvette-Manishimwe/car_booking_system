const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const db = require('./db');
const bcrypt = require('bcrypt');
const morgan = require('morgan');
const jwt = require('jsonwebtoken');
const authenticateToken = require('./middleware/authenticate');
require('dotenv').config();


const app = express();
app.use(bodyParser.json());
app.use(cors({
  origin: '*',  // Allow all origins
  methods: ['GET', 'POST'],
  allowedHeaders: ['Content-Type']
}));
app.use(morgan('dev'));

// Register route
app.post('/register', async (req, res) => {
  const { name, email, password, phone, category } = req.body;

  try {
    // Hash the password for security
    const hashedPassword = await bcrypt.hash(password, 10);

    // Insert user data into MySQL
    const query = 'INSERT INTO users (name, email, password, phone, category) VALUES (?, ?, ?, ?, ?)';
    db.query(query, [name, email, hashedPassword, phone, category], (err, result) => {
      if (err) {
        console.error('Error during registration:', err);
        res.status(500).send('Registration failed');
      } else {
        res.status(200).send('Registration successful');
      }
    });
  } catch (error) {
    console.error('Error during registration:', error);
    res.status(500).send('Registration failed');
  }
});

// Login route


app.post('/login-passenger', async (req, res) => {
  const { email, password } = req.body;

  // Check if email and password are provided
  if (!email || !password) {
    return res.status(400).json({
      success: false,
      message: 'Please provide both email and password',
    });
  }

  // Query to check for the user in the database
  const query = 'SELECT * FROM users WHERE email = ? AND category = "Passenger"';
  
  db.query(query, [email], async (err, results) => {
    if (err) {
      console.error('Error during login:', err);
      return res.status(500).json({
        success: false,
        message: 'An error occurred',
        error: err,
      });
    }

    // Check if the user exists
    if (results.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password',
      });
    }

    const user = results[0];
    
    // Compare provided password with stored hashed password
    const passwordMatches = await bcrypt.compare(password, user.password);
    if (!passwordMatches) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password',
      });
    }

    // Generate a token for the passenger
    const token = jwt.sign({ id: user.id, category: user.category }, process.env.JWT_SECRET_KEY, { expiresIn: '1h' });

    // Respond with success and user details
    res.json({
      success: true,
      token: token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        category: user.category,
      },
    });
  });
});


app.post('/login-driver', async (req, res) => {
  const { email, password } = req.body;

  // Check if email and password are provided
  if (!email || !password) {
    return res.status(400).json({
      success: false,
      message: 'Please provide both email and password',
    });
  }

  // Query to find the driver by email
  const query = 'SELECT * FROM users WHERE email = ? AND category = "Driver"';
  
  db.query(query, [email], async (err, results) => {
    if (err) {
      console.error('Error during login:', err);
      return res.status(500).json({
        success: false,
        message: 'An error occurred',
        error: err,
      });
    }

    if (results.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password',
      });
    }

    const user = results[0];

    // Validate the password
    const passwordMatches = await bcrypt.compare(password, user.password);
    if (!passwordMatches) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password',
      });
    }

    // Generate a token for the user
    const token = jwt.sign({ id: user.id, category: user.category }, process.env.JWT_SECRET_KEY, { expiresIn: '1h' });

    res.json({
      success: true,
      token: token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        category: user.category,
      },
    });
  });
});


app.get('/trip-details/:id', (req, res) => {
  const tripId = req.params.id;

  // Ensure tripId is a number to prevent SQL injection
  const tripIdNum = parseInt(tripId, 10);
  if (isNaN(tripIdNum)) {
    return res.status(400).json({ success: false, message: 'Invalid trip ID' });
  }

  // Modify the query to fetch details from the trips table and include passenger information, including booked_seats
  const query = `
    SELECT trips.id AS trip_id, trips.destination, trips.departure_location, trips.trip_time, trips.plate_number,
           trips.available_seats, trips.amount, trips.date_created,
           users.name AS passenger_name, bookings.passenger_id, bookings.booking_time, bookings.status, bookings.booked_seats
    FROM trips
    LEFT JOIN bookings ON trips.id = bookings.trip_id
    LEFT JOIN users ON bookings.passenger_id = users.id
    WHERE trips.id = ?;
  `;

  db.query(query, [tripIdNum], (error, rows) => {
    if (error) {
      console.error('Error fetching trip details:', error);
      return res.status(500).json({ success: false, message: 'Server error' });
    }

    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Trip not found' });
    }

    // Extract trip details including booked_seats
    const tripDetails = {
      tripId: rows[0].trip_id,
      destination: rows[0].destination,
      departureLocation: rows[0].departure_location,
      tripTime: rows[0].trip_time,
      plateNumber: rows[0].plate_number,
      availableSeats: rows[0].available_seats,
      amount: rows[0].amount,
      dateCreated: rows[0].date_created,
      passengers: rows.map(row => ({
        id: row.passenger_id,
        name: row.passenger_name,
        bookingTime: row.booking_time,
        status: row.status,
        seatsBooked: row.booked_seats // Make sure booked_seats is included here
      }))
    };

    res.status(200).json(tripDetails);
  });
});











// Fetch trips
app.get('/trips', (req, res) => {
  const sql = 'SELECT * FROM Trips ORDER BY date_created ';
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching trips:', err);
      return res.status(500).json({
        success: false,
        message: 'Error fetching trips',
      });
    }
    res.json(results);
  });
});

app.get('/bookings', authenticateToken, (req, res) => {
  const passengerId = req.userId; // Get the user ID from the request
  const query = `
      SELECT 
    bookings.id AS booking_id, 
    trips.id AS trip_id, 
    trips.destination, 
    trips.departure_location, 
    trips.available_seats, 
    trips.amount,  /* Correctly include the amount field */
    bookings.booking_time, 
    users.name AS driver_name,
    trips.driver_id AS driver_id  /* Include driver_id from trips */
FROM 
    bookings
JOIN 
    trips ON bookings.trip_id = trips.id
JOIN 
    users ON trips.driver_id = users.id
WHERE 
    bookings.passenger_id = ?;
`;

  db.query(query, [passengerId], (err, results) => {
      if (err) {
          console.error(err);
          return res.status(500).send('Server error');
      }
      res.json(results);
  });
});



app.post('/pay_trip/:bookingId', async (req, res) => {
  const bookingId = req.params.bookingId;

  try {
    // Check if the booking exists and is currently 'Pending'
    const [bookingResult] = await pool.query('SELECT status FROM bookings WHERE id = ?', [bookingId]);
    
    // If booking not found, return a 404
    if (bookingResult.length === 0) {
      return res.status(404).json({ message: 'Booking not found.' });
    }

    // Check if the booking status is 'Pending'
    const bookingStatus = bookingResult[0].status;
    if (bookingStatus !== 'Pending') {
      return res.status(400).json({ message: 'Booking cannot be paid because it is not pending.' });
    }

    // Update the status of the booking to 'Paid'
    const [result] = await pool.query('UPDATE bookings SET status = ? WHERE id = ?', ['Paid', bookingId]);

    if (result.affectedRows > 0) {
      res.status(200).json({ message: 'Payment successful!' });
    } else {
      res.status(404).json({ message: 'Booking not found or already paid.' });
    }
  } catch (error) {
    console.error('Error processing payment:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});



// Add a trip
app.post('/add_trip', authenticateToken, (req, res) => {
  const { plate_number, destination, departure_location, trip_time, available_seats, amount } = req.body;
  const driver_id = req.driver_id;

  if (!driver_id) {
      return res.status(403).json({ success: false, message: 'Only drivers can add trips' });
  }

  const sql = 'INSERT INTO Trips (driver_id, plate_number, destination, departure_location, trip_time, available_seats, amount) VALUES (?, ?, ?, ?, ?, ?, ?)';
  
  db.query(sql, [driver_id, plate_number, destination, departure_location, trip_time, available_seats, amount], (err, result) => {
      if (err) {
          console.error('Error adding trip:', err);
          return res.status(500).json({ success: false, message: 'Error adding trip' });
      }
      res.json({ success: true, tripId: result.insertId });
  });
});


// Get earnings and average rating
// Get earnings and average rating
app.get('/earnings', authenticateToken, (req, res) => {
  const driver_id = req.driver_id;  // Ensure driver_id is available

  // Query to get the total earnings of the driver
  const earningsQuery = 'SELECT SUM(amount) AS totalEarnings FROM Trips WHERE driver_id = ?';
  
  db.query(earningsQuery, [driver_id], (err, earningsResult) => {
    if (err) {
      console.error('Error fetching earnings:', err);
      return res.status(500).json({ error: 'Failed to fetch earnings' });
    }

    // Query to get the average rating of the driver
    const ratingQuery = 'SELECT AVG(rating) AS averageRating FROM ratings WHERE driver_id = ?';
    
    db.query(ratingQuery, [driver_id], (err, ratingResult) => {
      if (err) {
        console.error('Error fetching rating:', err);
        return res.status(500).json({ error: 'Failed to fetch rating' });
      }

      // Extract and return the earnings and rating, default to 0 if not available
      const totalEarnings = parseFloat(earningsResult[0]?.totalEarnings) || 0;
      const averageRating = parseFloat(ratingResult[0]?.averageRating) || 0;

      res.json({ totalEarnings, averageRating });
    });
  });
});






// Get driver details
app.get('/driver-details', authenticateToken, (req, res) => {
  const driverId = req.driver_id; // Get driver_id from token

  const sql = 'SELECT name, email FROM users WHERE id = ?';
  db.query(sql, [driverId], (err, result) => {
    if (err) {
      console.error('Error fetching driver details:', err);
      return res.status(500).json({
        success: false,
        message: 'Error fetching driver details',
      });
    }
    if (result.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Driver not found',
      });
    }
    res.json(result[0]);
  });
});


app.get('/available_drivers', (req, res) => {
  const { departure_location, destination } = req.query;

  const query = `
    SELECT users.id, users.name, Trips.id AS trip_id, Trips.plate_number, Trips.trip_time, Trips.available_seats, Trips.amount
    FROM users
    INNER JOIN Trips ON users.id = Trips.driver_id
    WHERE Trips.departure_location = ? AND Trips.destination = ? AND Trips.available_seats > 0;
  `;

  db.query(query, [departure_location, destination], (err, results) => {
    if (err) {
      console.error('Error fetching available drivers:', err);
      return res.status(500).json({
        success: false,
        message: 'Error fetching available drivers',
      });
    }

    if (results.length === 0) {
      // If no drivers are available, suggest other drivers (from different locations)
      const alternativeQuery = `
        SELECT users.id, users.name, Trips.id AS trip_id, Trips.plate_number, Trips.trip_time, Trips.available_seats, Trips.amount
        FROM users
        INNER JOIN Trips ON users.id = Trips.driver_id
        WHERE Trips.available_seats > 0
        ORDER BY Trips.trip_time ASC
        LIMIT 5;  -- Adjust limit as needed
      `;

      db.query(alternativeQuery, (err, alternativeResults) => {
        if (err) {
          console.error('Error fetching alternative drivers:', err);
          return res.status(500).json({
            success: false,
            message: 'Error fetching alternative drivers',
          });
        }

        res.json({
          success: true,
          drivers: alternativeResults,
          message: 'No drivers available for this route. Showing alternative drivers.',
        });
      });
    } else {
      res.json({
        success: true,
        drivers: results,
      });
    }
  });
});


app.post('/rate_driver', authenticateToken, (req, res) => {
  const { booking_id, rating } = req.body;

  // Validate input
  if (!booking_id || !rating || rating < 1 || rating > 5) {
    return res.status(400).json({ success: false, message: 'Invalid input.' });
  }

  // Ensure the user making the request is a passenger and has booked the trip
  const userId = req.passenger_id; // Assuming JWT contains the passenger's ID

  // Check if the booking exists for the logged-in passenger
  db.query('SELECT trip_id, driver_id FROM bookings WHERE id = ? AND passenger_id = ?', [booking_id, userId], (err, results) => {
    if (err) return res.status(500).json({ success: false, message: err.message });
    
    if (results.length === 0) {
      return res.status(403).json({ success: false, message: 'You did not book this trip.' });
    }

    // Extract the trip_id and driver_id from the booking record
    const { trip_id, driver_id } = results[0];

    // If validation passes, insert the rating into the database
    db.query(
      'INSERT INTO ratings (booking_id, trip_id, driver_id, rating, passenger_id) VALUES (?, ?, ?, ?, ?)',
      [booking_id, trip_id, driver_id, rating, userId], // Use booking_id here
      (err, result) => {
        if (err) {
          return res.status(500).json({ success: false, message: err.message });
        }
        res.json({ success: true, message: 'Rating submitted successfully!', ratingId: result.insertId });
      }
    );
  });
});



app.get('/check_rating', (req, res) => {
  const bookingId = req.query.booking_id; // Get booking_id from the request query

  // Check if bookingId is provided
  if (!bookingId) {
    return res.status(400).json({ success: false, message: 'Booking ID is required' });
  }

  const query = `
      SELECT COUNT(*) AS rating_count 
      FROM ratings 
      WHERE booking_id = ?;`; // Check if rating exists for the given booking ID

  db.query(query, [bookingId], (err, results) => {
    if (err) {
      console.error(err);
      return res.status(500).send('Server error');
    }

    const ratingExists = results[0].rating_count > 0; // Check if the rating exists
    res.json({ ratingSubmitted: ratingExists }); // Return the result
  });
});








app.get('/logged_in_as_passenger', authenticateToken, (req, res) => {

  console.log(req.query); // Log incoming query parameters
  const userId = req.query.userId;

  const query = `
    SELECT u.id AS passenger_id, u.name, u.email, t.id AS trip_id, t.driver_id
    FROM users u
    LEFT JOIN bookings b ON u.id = b.passenger_id
    LEFT JOIN trips t ON b.trip_id = t.id
    WHERE u.id = ? AND u.category = 'passenger'`;

  db.query(query, [userId], (err, results) => {
    if (err) {
      console.error('Error fetching passenger data:', err);
      return res.status(500).json({
        success: false,
        message: 'Error fetching passenger data',
      });
    }

    if (results.length > 0) {
      const passengerData = results[0];
      res.json({
        success: true,
        passenger: {
          id: passengerData.passenger_id,
          name: passengerData.name,
          email: passengerData.email,
          trip: {
            trip_id: passengerData.trip_id,
            driver_id: passengerData.driver_id,
          },
        },
      });
    } else {
      res.status(404).json({
        success: false,
        message: 'Passenger not found',
      });
    }
  });
});



// Route to get all locations
app.get('/locations', (req, res) => {
  db.query('SELECT name FROM locations', (err, results) => {
    if (err) {
      return res.status(500).json({ error: 'Failed to fetch locations' });
    }
    res.json({ locations: results.map(location => location.name) });
  });
});

// Route to search available rides (drivers)
app.post('/search_rides', (req, res) => {
  const { pickup, dropoff } = req.body;

  if (!pickup || !dropoff) {
    return res.status(400).json({ error: 'Pickup and dropoff locations are required' });
  }

  // Fetch available drivers
  const query = `
    SELECT name,phone, email
    FROM users 
    WHERE category = 'Driver'
  `;
  db.query(query, (err, results) => {
    if (err) {
      return res.status(500).json({ error: 'Failed to fetch drivers' });
    }
    res.json({ drivers: results });
  });
});


app.post('/book_trip', authenticateToken, (req, res) => {
  const { trip_id, number_of_seats, booking_time, passenger_name } = req.body;
  const passenger_id = req.passenger_id; // Assuming passenger_id is coming from authenticated token

  console.log("Passenger ID: ", passenger_id); // Log passenger ID
  console.log("Booking Details: ", { trip_id, number_of_seats, booking_time, passenger_name });

  if (!passenger_id) {
    return res.status(400).json({ success: false, message: 'Passenger ID not found' });
  }

  const seatCheckQuery = `SELECT available_seats, driver_id FROM Trips WHERE id = ?`;
  db.query(seatCheckQuery, [trip_id], (err, results) => {
    if (err) {
      console.error('Error fetching trip data:', err);
      return res.status(500).json({
        success: false,
        message: 'Error fetching trip data',
      });
    }

    if (results.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Trip not found',
      });
    }

    const availableSeats = results[0].available_seats;
    const driver_id = results[0].driver_id; 

    console.log("Available Seats: ", availableSeats); // Log available seats

    if (availableSeats < number_of_seats) {
      return res.status(400).json({
        success: false,
        message: 'Not enough available seats',
        available_seats: availableSeats,
      });
    }

    const bookingQuery = `
      INSERT INTO bookings (trip_id, passenger_id, driver_id, booking_time, status, booked_seats) 
      VALUES (?, ?, ?, ?, 'Pending', ?);
    `;
    
    // Pass number_of_seats as booked_seats
    db.query(bookingQuery, [trip_id, passenger_id, driver_id, booking_time, number_of_seats], (err, result) => {
      if (err) {
        console.error('Error making the booking:', err);
        return res.status(500).json({
          success: false,
          message: 'Error making the booking',
        });
      }

      const message = 'New booking request';
      createNotification(driver_id, passenger_id, trip_id, message, 'Pending');

      const updateSeatsQuery = `UPDATE Trips SET available_seats = available_seats - ? WHERE id = ?`;
      db.query(updateSeatsQuery, [number_of_seats, trip_id], (err, updateResult) => {
        if (err) {
          console.error('Error updating seats:', err);
          return res.status(500).json({
            success: false,
            message: 'Error updating available seats',
          });
        }

        res.status(200).json({
          success: true,
          message: 'Booking successful, notification sent to driver',
        });
      });
    });
  });
});


 







app.get('/passenger-details', authenticateToken, (req, res) => {
  const passengerId = req.passenger_id;

  console.log('Passenger ID:', passengerId);

  const sql = 'SELECT name, email FROM users WHERE id = ?';
  db.query(sql, [passengerId], (err, results) => {
    if (err) {
      console.error('Error fetching passenger details:', err.message);
      return res.status(500).json({ success: false, message: 'Database error' });
    }

    if (results.length === 0) {
      console.log('No passenger found with ID:', passengerId);
      return res.status(404).json({ success: false, message: 'Passenger not found' });
    }

    res.json({
      success: true,
      name: results[0].name,
      email: results[0].email,
    });
  });
});


app.get('/get_current_trip', authenticateToken, (req, res) => {
  const passengerId = req.passenger_id;

  // SQL query to fetch the current trip where the `driver_id` is not NULL
  const query = `
    SELECT trips.id, trips.driver_id, trips.plate_number, trips.destination, 
           trips.departure_location, trips.trip_time, trips.available_seats, trips.amount, trips.date_created
    FROM trips
    WHERE trips.driver_id IS NOT NULL
    ORDER BY trips.date_created DESC
    LIMIT 1
  `;

  db.query(query, [passengerId], (err, results) => {
    if (err) {
      console.error('Error fetching current trip:', err);
      return res.status(500).json({ message: 'An error occurred while fetching the current trip' });
    }

    if (results.length === 0) {
      return res.status(404).json({ message: 'No ongoing trip found for this passenger' });
    }

    const currentTrip = results[0];

    // Respond with the current trip details
    res.json({
      trip: {
        id: currentTrip.id,
        driver_id: currentTrip.driver_id,
        plate_number: currentTrip.plate_number,
        destination: currentTrip.destination,
        departure_location: currentTrip.departure_location,
        trip_time: currentTrip.trip_time,
        available_seats: currentTrip.available_seats,
        amount: currentTrip.amount,
        date_created: currentTrip.date_created,
      }
    });
  });
});


app.get('/get_trip_details/:tripId', (req, res) => {
  const tripId = req.params.tripId;

  // SQL query to fetch trip details by ID
  const query = 'SELECT available_seats FROM Trips WHERE id = ?';


  db.query(query, [tripId], (err, results) => {
    if (err) {
      console.error('Error fetching trip details:', err);
      return res.status(500).json({ success: false, message: 'Error fetching trip details' });
    }

    if (results.length === 0) {
      return res.status(404).json({ success: false, message: 'Trip not found' });
    }

    // Send the trip details as response
    res.status(200).json({ success: true, data: results[0] });
  });
});



// Define the route in Express.js
app.get('/nearby_drivers', (req, res) => {
  const { departure_location, destination } = req.query;

  // Check if query parameters are provided
  if (!departure_location || !destination) {
    return res.status(400).json({ message: 'Please provide both departure location and destination' });
  }

  // First query: Search for drivers that match the departure_location and destination
  const primaryQuery = `
    SELECT * FROM trips
    WHERE departure_location = ? AND destination = ?;
  `;

  db.query(primaryQuery, [departure_location, destination], (err, results) => {
    if (err) {
      return res.status(500).json({ message: 'Database query failed' });
    }

    // If drivers are found, return them
    if (results.length > 0) {
      return res.status(200).json({ drivers: results });
    }

    // If no drivers are found, execute a fallback query to get all available drivers
    const fallbackQuery = `
      SELECT * FROM trips
      WHERE available_seats > 0;
    `;

    db.query(fallbackQuery, (err, fallbackResults) => {
      if (err) {
        return res.status(500).json({ message: 'Database query failed' });
      }

      // Return the fallback available drivers
      if (fallbackResults.length > 0) {
        return res.status(200).json({
          message: 'No drivers found for the specified route, but here are other available drivers',
          drivers: fallbackResults
        });
      } else {
        // If no fallback drivers are found either, return an appropriate message
        return res.status(404).json({ message: 'No drivers available at this time' });
      }
    });
  });
});



// Fetch notifications for the driver
app.get('/driver-notifications', authenticateToken, (req, res) => {
  if (req.category !== 'Driver') {
      return res.status(403).json({ success: false, message: 'Access denied' });
  }

  const query = `SELECT * FROM notifications WHERE driver_id = ? ORDER BY created_at DESC`;
  db.query(query, [req.userId], (err, results) => {
      if (err) {
          console.error('Error fetching driver notifications:', err);
          return res.status(500).json({ success: false, message: 'Error fetching notifications' });
      }
      res.status(200).json(results);
  });
});

// Fetch notifications for the passenger
app.get('/passenger-notifications', authenticateToken, (req, res) => {
  if (req.category !== 'Passenger') {
      return res.status(403).json({ success: false, message: 'Access denied' });
  }

  const query = `SELECT * FROM notifications WHERE passenger_id = ?  ORDER BY created_at DESC`;
  db.query(query, [req.userId], (err, results) => {
      if (err) {
          console.error('Error fetching passenger notifications:', err);
          return res.status(500).json({ success: false, message: 'Error fetching notifications' });
      }
      res.status(200).json(results);
  });
});

// Example of a function to create a new notification
function createNotification(driverId, passengerId, tripId, message, status = 'Pending') {
  const query = `INSERT INTO notifications (driver_id, passenger_id, trip_id, message, status) VALUES (?, ?, ?, ?, ?)`;
  db.query(query, [driverId, passengerId, tripId, message, status], (err) => {
      if (err) {
          console.error('Error creating notification:', err);
      }
  });
}



// POST route to send a message from the driver to the passenger
app.post('/send-message', authenticateToken, (req, res) => {
  const { trip_id, message } = req.body;

  // Ensure the user is a driver
  if (req.category !== 'Driver') {
    return res.status(403).json({ success: false, message: 'Access denied' });
  }

  // First, fetch the passenger_id from the bookings table based on the trip_id
  const getPassengerQuery = `
    SELECT passenger_id FROM bookings WHERE trip_id = ? AND driver_id = ?;
  `;

  // Use the trip_id and driver_id from the request (driver_id is from the authenticated user)
  db.query(getPassengerQuery, [trip_id, req.userId], (err, result) => {
    if (err) {
      console.error('Error fetching passenger:', err);
      return res.status(500).json({
        success: false,
        message: 'Error fetching passenger details',
      });
    }

    // Check if a result was found
    if (result.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No booking found for the given trip and driver',
      });
    }

    // Get the passenger_id from the query result
    const passenger_id = result[0].passenger_id;

    // Now insert the message into the notifications table
    const insertMessageQuery = `
      INSERT INTO notifications (driver_id, passenger_id, trip_id, message, status)
      VALUES (?, ?, ?, ?, 'Confirmed');
    `;

    // Insert driver_id (from the authenticated user), passenger_id (from the query), trip_id, and the message
    db.query(insertMessageQuery, [req.userId, passenger_id, trip_id, message], (err, result) => {
      if (err) {
        console.error('Error inserting notification:', err);
        return res.status(500).json({
          success: false,
          message: 'Error sending message',
        });
      }

      // Successfully inserted the message
      return res.status(200).json({
        success: true,
        message: 'Message sent to passenger successfully',
      });
    });
  });
});



app.get('/get_notifications', authenticateToken, (req, res) => {
  const passengerId = req.passenger_id; // Get passenger_id from the authenticated user
  console.log('Received Passenger ID:', passengerId);

  const query = `
      SELECT * FROM notifications
      WHERE passenger_id = ? AND status = 'Confirmed';
  `;

  db.query(query, [passengerId], (error, results) => {
      if (error) {
          console.error('Error fetching notifications:', error);
          return res.status(500).json({ success: false, message: 'Server error' });
      }

      // If no results are found, return an empty array
      res.status(200).json(results); // Return notifications
  })
});










const PORT = 5000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
