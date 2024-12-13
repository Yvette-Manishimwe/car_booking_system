const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const db = require('./db');
const bcrypt = require('bcrypt');
const fs = require('fs')
const morgan = require('morgan');
const jwt = require('jsonwebtoken');
const authenticateToken = require('./middleware/authenticate');
const otpGenerator = require('otp-generator');
const nodemailer = require('nodemailer'); // For email OTP
const crypto = require('crypto'); // For secure OTP storage
const multer = require('multer');
const path = require('path');
const cron = require('node-cron');
require('dotenv').config();
const Tesseract = require('tesseract.js');


const app = express();
app.use(bodyParser.json());
app.use(cors({
  origin: '*',  // Allow all origins
  methods: ['GET', 'POST'],
  allowedHeaders: ['Content-Type']
}));
app.use(morgan('dev'));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Multer storage configuration for profile pictures
const profilePictureStorage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, path.join(__dirname, 'uploads')); // Profile pictures will be saved in 'uploads'
  },
  filename: function (req, file, cb) {
    cb(null, Date.now() + path.extname(file.originalname)); // Unique filename based on timestamp
  }
});

const uploadProfilePicture = multer({ storage: profilePictureStorage });  


const paymentStorage = multer.diskStorage({
  destination: function (req, file, cb) {
    // Specify the 'uploads/payments' directory for payment proofs
    const destinationPath = path.join(__dirname, 'uploads', 'payments');
    
    // If necessary, ensure the 'payments' directory exists
    if (!fs.existsSync(destinationPath)) {
      fs.mkdirSync(destinationPath, { recursive: true });
    }

    // Set the destination for the file
    cb(null, destinationPath);
  },
  filename: function (req, file, cb) {
    // Use timestamp for unique filenames
    cb(null, Date.now() + path.extname(file.originalname));
  }
});

// Create the multer instance
const uploadPayment = multer({ storage: paymentStorage });

// User Registration API
app.post('/register', uploadProfilePicture.single('profile_picture'), async (req, res) => {
  const { name, email, password, phone, category } = req.body;

  // Validate the required fields
  if (!name || !email || !password || !phone || !category) {
    return res.status(400).json({ message: 'All fields are required' });
  }

  // Check if the user already exists
  db.query('SELECT * FROM users WHERE email = ?', [email], (err, result) => {
    if (err) {
      return res.status(500).json({ message: 'Database error', error: err });
    }
    if (result.length > 0) {
      return res.status(400).json({ message: 'Email already exists' });
    }

    // Hash the password before saving
    bcrypt.hash(password, 10, (err, hashedPassword) => {
      if (err) {
        return res.status(500).json({ message: 'Error hashing password', error: err });
      }

      // If a profile picture is uploaded, get its URL
            // If a profile picture is uploaded, get its URL
            let profilePictureUrl = null;
            if (req.file) {
              // Use the relative URL (for example: /uploads/filename.jpg)
              profilePictureUrl = `/uploads/${req.file.filename}`;
            }

      // Insert the new user into the database, including the profile picture URL if available
      const query = 'INSERT INTO users (name, email, password, phone, category, profile_picture) VALUES (?, ?, ?, ?, ?, ?)';
      db.query(query, [name, email, hashedPassword, phone, category, profilePictureUrl], (err, result) => {
        if (err) {
          return res.status(500).json({ message: 'Database error', error: err });
        }

        return res.status(201).json({ message: 'User registered successfully' });
      });
    });
  });
});



// Configure nodemailer
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USERNAME,
    pass: process.env.EMAIL_PASSWORD,
  },
});

app.post('/login', async (req, res) => {
  const { email, password, category } = req.body;

  if (!email || !password || !category) {
    return res.status(400).json({
      success: false,
      message: 'Please provide email, password, and category',
    });
  }

  console.log('Login Request Body:', req.body);  // Make sure category is sent

  // Query to find the user by email and category
  const query = 'SELECT * FROM users WHERE email = ? AND category = ?';
  db.query(query, [email, category], async (err, results) => {
    if (err) {
      console.error('Error during query:', err);
      return res.status(500).json({
        success: false,
        message: 'An error occurred during login',
      });
    }

    if (results.length === 0) {
      console.log('User not found with provided email and category');
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password',
      });
    }

    const user = results[0];
    console.log('User found:', user);

    // Validate the password using bcrypt
    const passwordMatches = await bcrypt.compare(password, user.password);
    if (!passwordMatches) {
      console.log('Password does not match for user:', email);
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password',
      });
    }

    // OTP generation and validation
    const otp = crypto.randomInt(100000, 999999); // 6-digit OTP
    const otpExpires = Date.now() + 10 * 60 * 1000; // OTP valid for 10 minutes

    const otpQuery =
      'INSERT INTO otps (email, otp, expires_at) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE otp = ?, expires_at = ?';
    db.query(otpQuery, [email, otp, otpExpires, otp, otpExpires], (otpErr) => {
      if (otpErr) {
        console.error('Error storing OTP:', otpErr);
        return res.status(500).json({
          success: false,
          message: 'Failed to generate OTP',
        });
      }

      // Send OTP to the user's email
      const mailOptions = {
        from: process.env.EMAIL_USERNAME,
        to: email,
        subject: 'Your OTP for Login',
        text: `Your OTP is: ${otp}. It is valid for 10 minutes.`,
      };

      transporter.sendMail(mailOptions, (mailErr) => {
        if (mailErr) {
          console.error('Error sending OTP email:', mailErr);
          return res.status(500).json({
            success: false,
            message: 'Failed to send OTP',
          });
        }

        res.status(200).json({
          success: true,
          message: 'OTP sent to your email. Please verify to complete login.',
        });
      });
    });
  });
});


// OTP Verification API
app.post('/verify-otp', async (req, res) => {
  const { email, otp } = req.body;

  // Validate input
  if (!email || !otp) {
    return res.status(400).json({
      success: false,
      message: 'Please provide email and OTP',
    });
  }

  // Query to validate OTP
  const query = 'SELECT * FROM otps WHERE email = ? AND otp = ?';
  db.query(query, [email, otp], (err, results) => {
    if (err) {
      console.error('Error verifying OTP:', err);
      return res.status(500).json({
        success: false,
        message: 'An error occurred during OTP verification',
      });
    }

    if (results.length === 0 || Date.now() > results[0].expires_at) {
      return res.status(401).json({
        success: false,
        message: 'Invalid or expired OTP',
      });
    }

    // OTP is valid, find user
    const userQuery = 'SELECT * FROM users WHERE email = ?';
    db.query(userQuery, [email], (userErr, userResults) => {
      if (userErr || userResults.length === 0) {
        console.error('Error fetching user:', userErr);
        return res.status(500).json({
          success: false,
          message: 'Failed to fetch user details',
        });
      }

      const user = userResults[0];

      // Generate JWT token
      const token = jwt.sign(
        { id: user.id, category: user.category },
        process.env.JWT_SECRET_KEY,
        { expiresIn: '1h' }
      );

      res.json({
        success: true,
        token: token,
        passenger_id: user.id,
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          category: user.category,
        },
      });
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
           trips.available_seats,trips.date_created,
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
app.get('/trips',authenticateToken, (req, res) => {
  const driverId= req.driver_id;
  const sql = 'SELECT * FROM Trips  WHERE driver_id = ? ORDER BY date_created ';
  db.query(sql,[driverId], (err, results) => {
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
  const passengerId = req.passenger_id;
  const query = `
      SELECT 
    bookings.id AS booking_id, 
    trips.id AS trip_id, 
    trips.destination, 
    trips.departure_location, 
    trips.available_seats, 
    bookings.booking_time, 
    users.name AS driver_name,
    trips.driver_id AS driver_id, /* Include driver_id from trips */
    bookings.booked_seats AS booked_seats
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

  // Validate plate number using regex for uppercase letters and specific format
  const plateNumberPattern = /^R[A-Z]{2}[0-9]{3}[A-Z]{1}$/;
  
  // Check if the plate number matches the required format
  if (!plateNumberPattern.test(plate_number)) {
      return res.status(400).json({ success: false, message: 'Invalid plate number format. Plate number should start with "R", followed by 2 uppercase letters, 3 digits, and 1 uppercase letter.' });
  }

  // Ensure the driver_id exists
  if (!driver_id) {
      return res.status(403).json({ success: false, message: 'Only drivers can add trips' });
  }

  // SQL query to insert the new trip into the database
  const sql = 'INSERT INTO Trips (driver_id, plate_number, destination, departure_location, trip_time, available_seats) VALUES (?, ?, ?, ?, ?, ?)';
  
  // Execute the query to insert the trip data
  db.query(sql, [driver_id, plate_number, destination, departure_location, trip_time, available_seats], (err, result) => {
      if (err) {
          console.error('Error adding trip:', err);
          return res.status(500).json({ success: false, message: 'Error adding trip' });
      }
      res.json({ success: true, tripId: result.insertId });
  });
});


// Add this to your cron job setup
cron.schedule('0 0 * * *', () => {
  const unpauseQuery = `
    UPDATE users 
    SET status = "unpaused", paused_at = NULL 
    WHERE status = "paused" AND paused_at <= DATE_SUB(NOW(), INTERVAL 7 DAY)
  `;

  db.query(unpauseQuery, (err, result) => {
    if (err) {
      console.error('Error unpausing drivers:', err);
    } else {
      console.log(`Unpaused ${result.affectedRows} driver(s).`);
    }
  });
});


// Fetch earnings and average rating for a driver
app.get('/earnings', authenticateToken, (req, res) => {
  const driver_id = req.driver_id;

  const ratingQuery = `
      SELECT AVG(rating) AS averageRating, COUNT(rating) AS totalRatings
      FROM ratings
      WHERE driver_id = ? AND rating_date >= DATE_SUB(NOW(), INTERVAL 7 DAY)
  `;

  db.query(ratingQuery, [driver_id], (err, ratingResult) => {
      if (err) {
          console.error('Error fetching rating:', err);
          return res.status(500).json({ error: 'Failed to fetch earnings data' });
      }

      const averageRating = parseFloat(ratingResult[0]?.averageRating) || 0;
      const totalRatings = ratingResult[0]?.totalRatings || 0;

      const checkLowRatingQuery = `SELECT low_rating_start, status FROM users WHERE id = ?`;

      db.query(checkLowRatingQuery, [driver_id], (checkErr, userResult) => {
          if (checkErr) {
              console.error('Error checking low rating start:', checkErr);
              return res.status(500).json({ error: 'Failed to check driver status' });
          }

          const lowRatingStart = userResult[0]?.low_rating_start;
          const driverStatus = userResult[0]?.status;

          if (averageRating < 3) {
              if (!lowRatingStart) {
                  const setLowRatingStartQuery = `UPDATE users SET low_rating_start = NOW() WHERE id = ?`;
                  db.query(setLowRatingStartQuery, [driver_id], (setErr) => {
                      if (setErr) {
                          console.error('Error setting low rating start:', setErr);
                          return res.status(500).json({ error: 'Failed to update driver status' });
                      }
                      console.log('Low rating start recorded.');
                      res.json({ averageRating, totalRatings });
                  });
              } else if (new Date(lowRatingStart) <= new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)) {
                  const pauseDriverQuery = `UPDATE users SET status = "paused", paused_at = NOW() WHERE id = ?`;
                  db.query(pauseDriverQuery, [driver_id], (pauseErr) => {
                      if (pauseErr) {
                          console.error('Error pausing driver:', pauseErr);
                          return res.status(500).json({ error: 'Failed to pause driver' });
                      }
                      console.log('Driver paused due to low weekly rating.');
                      res.json({ message: 'Driver paused due to low weekly rating.', averageRating, totalRatings });
                  });
              } else {
                  res.json({ averageRating, totalRatings });
              }
          } else {
              if (lowRatingStart) {
                  const resetLowRatingQuery = `UPDATE users SET low_rating_start = NULL WHERE id = ?`;
                  db.query(resetLowRatingQuery, [driver_id], (resetErr) => {
                      if (resetErr) {
                          console.error('Error resetting low rating start:', resetErr);
                          return res.status(500).json({ error: 'Failed to reset low rating start' });
                      }
                      console.log('Low rating start reset.');
                  });
              }
              res.json({ averageRating, totalRatings });
          }
      });
  });
});


// Send reminder for drivers with low ratings
app.post('/send-reminder', authenticateToken, (req, res) => {
  const driver_id = req.driver_id;

  const ratingQuery = `
    SELECT AVG(rating) AS averageRating
    FROM ratings
    WHERE driver_id = ?
  `;

  db.query(ratingQuery, [driver_id], (err, ratingResult) => {
    if (err) {
      console.error('Error fetching rating:', err);
      return res.status(500).json({ error: 'Failed to fetch rating' });
    }

    const averageRating = parseFloat(ratingResult[0]?.averageRating) || 0;

    if (averageRating < 3) {
      const reminderMessage = 'Your rating is below 3. Improve it to avoid being paused.';

      const reminderQuery = `
        INSERT INTO earnings_notifications (driver_id, message, status)
        VALUES (?, ?, ?)
      `;
      db.query(reminderQuery, [driver_id, reminderMessage, 'Unseen'], (insertErr) => {
        if (insertErr) {
          console.error('Error sending reminder:', insertErr);
          return res.status(500).json({ error: 'Failed to send reminder' });
        }

        console.log('Reminder sent to driver.');
        res.json({ message: 'Reminder sent to driver', averageRating });
      });
    } else {
      res.json({ message: 'Driver rating is fine.', averageRating });
    }
  });
});

// Fetch all reminders for a driver
app.get('/earnings-reminders', authenticateToken, (req, res) => {
  const driver_id = req.driver_id;

  const fetchRemindersQuery = `
    SELECT id, message, status, created_at 
    FROM earnings_notifications 
    WHERE driver_id = ?
    ORDER BY created_at DESC
  `;

  db.query(fetchRemindersQuery, [driver_id], (err, results) => {
    if (err) {
      console.error('Error fetching reminders:', err);
      return res.status(500).json({ error: 'Failed to fetch reminders' });
    }

    if (results.length === 0) {
      // If no reminders exist, include a default reminder
      return res.json({ 
        reminders: [{
          id: null,
          message: 'Remember that after 1 week with a low rating, you will be paused.',
          status: 'default',
          created_at: new Date().toISOString()
        }]
      });
    }

    res.json({ reminders: results });
  });
});



// Get available trips for a driver
app.get('/available-trips', authenticateToken, (req, res) => {
  const sql = `
    SELECT 
      users.name AS driver_name, 
      users.phone AS driver_phone, 
      trips.id AS trip_id, 
      trips.destination, 
      trips.departure_location, 
      trips.trip_time AS departure_time, 
      trips.available_seats,
      trips.plate_number 
    FROM trips
    JOIN users ON trips.driver_id = users.id
    WHERE trips.available_seats > 0
  `;

  db.query(sql, (err, result) => {
    if (err) {
      console.error('Error fetching available trips:', err);
      return res.status(500).json({
        success: false,
        message: 'Error fetching available trips',
      });
    }
    if (result.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No available trips found',
      });
    }
    res.json(result); // Return the available trips along with driver details
  });
});





app.post('/upload_proof/:bookingId', uploadPayment.single('proofOfPayment'), async (req, res) => {
  const { bookingId } = req.params;

  // Check if a file was uploaded
  if (!req.file) {
    return res.status(400).json({ error: 'No file uploaded' });
  }

  const proofFilePath = req.file.path;

  try {
    // Extract text from the uploaded image using Tesseract
    const { data: { text } } = await Tesseract.recognize(proofFilePath, 'eng');

    console.log('Extracted text:', text);

    // Normalize the extracted text
    const normalizedText = text.replace(/\s+/g, ' ').trim();
    console.log('Normalized text:', normalizedText);

    // Define a regex to match the payment confirmation message
    const paymentRegex = /Your payment of\s*(\d+(?:\.\d{1,2})?)\s*RWF\s*to\s*CELESTIN\s*(\d+)\s*has been completed at\s*(\d{4}-\d{2}-\d{2}\s*\d{2}:\d{2}:\d{2})/i;

    // Check if the extracted text matches the expected pattern
    const match = normalizedText.match(paymentRegex);
    console.log('Match result:', match);

    if (match) {
      const amount = match[1]; // Extracted payment amount
      const transactionId = match[2]; // Extracted transaction ID
      const date = match[3]; // Extracted date and time

      // SQL query to insert or update payment record
      const query = `
        INSERT INTO payments (booking_id, proof_of_payment, status)
        VALUES (?, ?, 'DONE')
        ON DUPLICATE KEY UPDATE proof_of_payment = VALUES(proof_of_payment), status = 'DONE';
      `;

      db.query(query, [bookingId, proofFilePath], (err, result) => {
        if (err) {
          console.error('Database query error:', err);
          return res.status(500).json({ error: 'Database query error' });
        }

        // Respond with success
        res.status(200).json({
          message: 'Payment successfully verified and recorded!',
          amount,
          transactionId,
          date,
          bookingId,
          proofFilePath
        });
      });
    } else {
      console.error('Payment verification failed. Extracted text:', normalizedText);
      return res.status(400).json({
        error: 'Payment verification failed. The expected message was not found.',
        debugText: normalizedText
      });
    }
  } catch (err) {
    console.error('Error processing image or extracting text:', err);
    res.status(500).json({ error: 'Error processing the image' });
  }
});

app.post('/verify_payment/:bookingId', (req, res) => {
  const { bookingId } = req.params;

  if (!bookingId || isNaN(bookingId)) {
    return res.status(400).json({ error: 'Invalid Booking ID' });
  }

  const updatePaymentQuery = `UPDATE payments SET status = 'DONE' WHERE booking_id = ?`;

  db.query(updatePaymentQuery, [bookingId], (err, paymentResult) => {
    if (err) {
      console.error('Database query error:', err);
      return res.status(500).json({ error: 'Database query error' });
    }

    if (paymentResult.affectedRows > 0) {
      const getDetailsQuery = `
        SELECT 
          b.id AS booking_id, 
          b.trip_id, 
          b.passenger_id, 
          b.driver_id, 
          n.id AS notification_id, 
          n.message, 
          n.status 
        FROM 
          bookings b
        LEFT JOIN 
          notifications n 
        ON 
          b.trip_id = n.trip_id 
        WHERE 
          b.id = ?`;

      db.query(getDetailsQuery, [bookingId], (err, detailsResult) => {
        if (err) {
          console.error('Database query error:', err);
          return res.status(500).json({ error: 'Error retrieving details' });
        }

        if (detailsResult.length > 0) {
          const { driver_id, passenger_id, trip_id, notification_id } = detailsResult[0];

          const createNotificationQuery = `
            INSERT INTO notifications (driver_id, passenger_id, trip_id, message, status) 
            VALUES (?, ?, ?, ?, 'Confirmed')`;

          const notificationMessage = `Trip ${trip_id} has been marked as completed.`;

          db.query(createNotificationQuery, [driver_id, passenger_id, trip_id, notificationMessage], (err) => {
            if (err) {
              console.error('Error creating notification:', err);
              return res.status(500).json({ error: 'Error creating notification' });
            }

            res.status(200).json({ message: 'Payment verified and notification sent to the driver.' });
          });
        } else {
          res.status(404).json({ error: 'No booking or notification details found' });
        }
      });
    } else {
      res.status(404).json({ error: 'Booking ID not found or payment already verified' });
    }
  });
});













// Get driver details
app.get('/driver-details', authenticateToken, (req, res) => {
  const driverId = req.driver_id; // Get driver_id from token

  const sql = 'SELECT name, email, phone, category, profile_picture FROM users WHERE id = ?';
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

  console.log('Querying for available drivers with:', {
    departure_location,
    destination,
  });

  const query = `
    SELECT users.id, users.name, users.profile_picture, Trips.id AS trip_id, Trips.plate_number, Trips.trip_time, Trips.available_seats
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
      console.log('No drivers found for the specified route. Checking for alternatives.');

      const alternativeQuery = `
        SELECT users.id, users.name,users.profile_picture, Trips.id AS trip_id, Trips.plate_number, Trips.trip_time, Trips.available_seats
        FROM users
        INNER JOIN Trips ON users.id = Trips.driver_id
        WHERE Trips.available_seats > 0
        ORDER BY Trips.trip_time ASC
        LIMIT 5;
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

  const sql = 'SELECT name, email,phone, category, profile_picture FROM users WHERE id = ?';
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
      phone: results[0].phone,
      category: results[0].category,
      profile_picture: results[0].profile_picture,
    });
  });
});


app.get('/get_current_trip', authenticateToken, (req, res) => {
  const passengerId = req.passenger_id;

  // SQL query to fetch the current trip where the `driver_id` is not NULL
  const query = `
    SELECT trips.id, trips.driver_id, trips.plate_number, trips.destination, 
           trips.departure_location, trips.trip_time, trips.available_seats, trips.date_created
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



// Fetch notifications with booking details for the driver
app.get('/driver-notifications', authenticateToken, (req, res) => {
  if (req.category !== 'Driver') {
    return res.status(403).json({ success: false, message: 'Access denied' });
  }

  const query = `
    SELECT 
      n.id, 
      n.trip_id, 
      n.passenger_id, 
      n.message, 
      n.status, 
      n.created_at, 
      u.name AS passenger_name, 
      u.phone AS passenger_phone,
      t.departure_location, 
      t.destination, 
      b.booking_time
    FROM notifications n
    JOIN users u ON n.passenger_id = u.id
    JOIN trips t ON n.trip_id = t.id
    JOIN bookings b ON b.trip_id = t.id AND b.passenger_id = n.passenger_id AND b.driver_id = n.driver_id
    WHERE n.driver_id = ?
    GROUP BY n.id -- Group by notification ID to ensure uniqueness
    ORDER BY n.created_at DESC;
  `;

  db.query(query, [req.userId], (err, results) => {
    if (err) {
      console.error('Error fetching driver notifications:', err);
      return res.status(500).json({ success: false, message: 'Error fetching notifications' });
    }
    res.status(200).json(results);
  });
});



// Endpoint to handle sending messages from driver to passenger
app.post('/send-message', authenticateToken, (req, res) => {
  const { notification_id, trip_id, message } = req.body;

  // Fetch driver_id and passenger_id from the notification
  const fetchDetailsQuery = `
    SELECT driver_id, passenger_id
    FROM notifications
    WHERE id = ?
  `;

  db.query(fetchDetailsQuery, [notification_id], (err, results) => {
    if (err) {
      console.error('Error fetching notification details:', err);
      return res.status(500).json({ error: 'Failed to fetch notification details' });
    }

    if (results.length === 0) {
      return res.status(404).json({ error: 'Notification not found' });
    }

    const { driver_id, passenger_id } = results[0];

    // Insert the message into the messages table
    const insertMessageQuery = `
      INSERT INTO messages (trip_id, driver_id, passenger_id, message, timestamp, status)
      VALUES (?, ?, ?, ?, NOW(), 'Sent')
    `;

    db.query(
      insertMessageQuery,
      [trip_id, driver_id, passenger_id, message],
      (err) => {
        if (err) {
          console.error('Error sending message:', err);
          return res.status(500).json({ error: 'Failed to send message' });
        }
        res.status(200).json({ success: true, message: 'Message sent successfully' });
      }
    );
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
      SELECT message, timestamp FROM messages
      WHERE passenger_id = ? AND status = 'Sent';
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
