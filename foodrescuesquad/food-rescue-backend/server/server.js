require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const mysql = require('mysql2/promise');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Database connection
const pool = mysql.createPool({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

// JWT Secret
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

// Authentication middleware
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    
    if (!token) return res.sendStatus(401);
    
    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) return res.sendStatus(403);
        req.user = user;
        next();
    });
};

// Routes will be added here

// Start server
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
// User registration
app.post('/api/register', async (req, res) => {
    try {
        const { firstName, lastName, email, phone, password, role } = req.body;
        
        // Check if user exists
        const [existingUser] = await pool.query('SELECT * FROM users WHERE email = ?', [email]);
        if (existingUser.length > 0) {
            return res.status(400).json({ message: 'User already exists' });
        }
        
        // Hash password
        const hashedPassword = await bcrypt.hash(password, 10);
        
        // Create user
        const [result] = await pool.query(
            'INSERT INTO users (first_name, last_name, email, phone, password_hash, role) VALUES (?, ?, ?, ?, ?, ?)',
            [firstName, lastName, email, phone, hashedPassword, role]
        );
        
        // Generate JWT token
        const user = { id: result.insertId, email, role };
        const token = jwt.sign(user, JWT_SECRET, { expiresIn: '1h' });
        
        res.status(201).json({ token, user: { id: result.insertId, firstName, lastName, email, phone, role } });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// User login
app.post('/api/login', async (req, res) => {
    try {
        const { email, password } = req.body;
        
        // Find user
        const [users] = await pool.query('SELECT * FROM users WHERE email = ?', [email]);
        if (users.length === 0) {
            return res.status(401).json({ message: 'Invalid credentials' });
        }
        
        const user = users[0];
        
        // Check password
        const isMatch = await bcrypt.compare(password, user.password_hash);
        if (!isMatch) {
            return res.status(401).json({ message: 'Invalid credentials' });
        }
        
        // Generate JWT token
        const tokenUser = { id: user.user_id, email: user.email, role: user.role };
        const token = jwt.sign(tokenUser, JWT_SECRET, { expiresIn: '1h' });
        
        res.json({ 
            token, 
            user: {
                id: user.user_id,
                firstName: user.first_name,
                lastName: user.last_name,
                email: user.email,
                phone: user.phone,
                role: user.role
            }
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});
// Create food donation (Donor)
app.post('/api/donations', authenticateToken, async (req, res) => {
    try {
        const { foodCategory, foodType, quantity, description, address, availableFrom, availableTo } = req.body;
        const donorId = req.user.id;
        
        // First, save the address
        const [addressResult] = await pool.query(
            'INSERT INTO addresses (user_id, street_address, city, state, zip_code, latitude, longitude) VALUES (?, ?, ?, ?, ?, ?, ?)',
            [donorId, address.street, address.city, address.state, address.zipCode, address.latitude, address.longitude]
        );
        
        // Then create the donation
        const [donationResult] = await pool.query(
            'INSERT INTO food_donations (donor_id, food_category, food_type, quantity, description, pickup_address_id, available_from, available_to) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            [donorId, foodCategory, foodType, quantity, description, addressResult.insertId, availableFrom, availableTo]
        );
        
        res.status(201).json({ 
            message: 'Donation created successfully',
            donationId: donationResult.insertId 
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Get all donations (for receivers/volunteers)
app.get('/api/donations', authenticateToken, async (req, res) => {
    try {
        const [donations] = await pool.query(`
            SELECT fd.*, 
                   a.street_address, a.city, a.state, a.zip_code, a.latitude, a.longitude,
                   u.first_name, u.last_name, u.phone
            FROM food_donations fd
            JOIN addresses a ON fd.pickup_address_id = a.address_id
            JOIN users u ON fd.donor_id = u.user_id
            WHERE fd.status = 'available'
        `);
        
        res.json(donations);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});
// Create food request (Receiver)
app.post('/api/requests', authenticateToken, async (req, res) => {
    try {
        const { foodCategory, foodType, quantity, description, address, neededBy } = req.body;
        const receiverId = req.user.id;
        
        // First, save the address
        const [addressResult] = await pool.query(
            'INSERT INTO addresses (user_id, street_address, city, state, zip_code, latitude, longitude) VALUES (?, ?, ?, ?, ?, ?, ?)',
            [receiverId, address.street, address.city, address.state, address.zipCode, address.latitude, address.longitude]
        );
        
        // Then create the request
        const [requestResult] = await pool.query(
            'INSERT INTO food_requests (receiver_id, food_category, food_type, quantity, description, delivery_address_id, needed_by) VALUES (?, ?, ?, ?, ?, ?, ?)',
            [receiverId, foodCategory, foodType, quantity, description, addressResult.insertId, neededBy]
        );
        
        res.status(201).json({ 
            message: 'Request created successfully',
            requestId: requestResult.insertId 
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Get all requests (for volunteers)
app.get('/api/requests', authenticateToken, async (req, res) => {
    try {
        const [requests] = await pool.query(`
            SELECT fr.*, 
                   a.street_address, a.city, a.state, a.zip_code, a.latitude, a.longitude,
                   u.first_name, u.last_name, u.phone
            FROM food_requests fr
            JOIN addresses a ON fr.delivery_address_id = a.address_id
            JOIN users u ON fr.receiver_id = u.user_id
            WHERE fr.status = 'pending'
        `);
        
        res.json(requests);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});
// Complete volunteer registration
app.post('/api/volunteers', authenticateToken, async (req, res) => {
    try {
        const { hasVehicle, vehicleType, emergencyContactName, emergencyContactPhone, availability, preferredTasks } = req.body;
        const userId = req.user.id;
        
        // Create volunteer record
        const [volunteerResult] = await pool.query(
            'INSERT INTO volunteers (user_id, has_vehicle, vehicle_type, emergency_contact_name, emergency_contact_phone) VALUES (?, ?, ?, ?, ?)',
            [userId, hasVehicle, vehicleType, emergencyContactName, emergencyContactPhone]
        );
        const volunteerId = volunteerResult.insertId;
        
        // Add availability
        for (const day of availability) {
            await pool.query(
                'INSERT INTO volunteer_availability (volunteer_id, day_of_week) VALUES (?, ?)',
                [volunteerId, day]
            );
        }
        
        // Add preferred tasks
        for (const task of preferredTasks) {
            await pool.query(
                'INSERT INTO volunteer_tasks (volunteer_id, task_type) VALUES (?, ?)',
                [volunteerId, task]
            );
        }
        
        res.status(201).json({ message: 'Volunteer registration completed' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});
