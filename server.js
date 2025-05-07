const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const app = express();

app.use(cors({ origin: '*' }));
app.use(express.json());

mongoose.connect('mongodb://localhost:27017/car', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
  .then(() => console.log("เชื่อมต่อ MongoDB สำเร็จ"))
  .catch(err => console.log("เกิดข้อผิดพลาดในการเชื่อมต่อ MongoDB:", err));

// ===================== Car Schema =====================
const carSchema = new mongoose.Schema({
  _id: Number,
  name: String,
  brand: String,
  coverimage: String,
  color: String,
  price: String,
  detail: String
});

const Car = mongoose.model('allcar', carSchema);

// ===================== User Schema =====================
const userSchema = new mongoose.Schema({
  name: String,
  email: { type: String, unique: true },
  phone: String,
  password: String
});

const User = mongoose.model('user', userSchema);

// ===================== Counter Schema =====================
const counterSchema = new mongoose.Schema({
  _id: String,
  seq: { type: Number, default: 0 }
});

const Counter = mongoose.model('counter', counterSchema);

async function getNextSequenceValue(sequenceName) {
  const sequenceDocument = await Counter.findOneAndUpdate(
    { _id: sequenceName },
    { $inc: { seq: 1 } },
    { new: true, upsert: true }
  );
  return sequenceDocument.seq;
}

// ===================== Booking Schema =====================
const bookingSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'user' },
  name: String,
  brand: String,
  color: String,
  startTime: Date,  // start time
  endTime: Date,    // end time
  totalPrice: Number,
}, { timestamps: true });

const Booking = mongoose.model('booking', bookingSchema);



// ===================== JWT Middleware =====================
const SECRET_KEY = 'mySecretKey123';

function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) return res.status(401).json({ message: 'ไม่พบ token' });

  jwt.verify(token, SECRET_KEY, (err, user) => {
    if (err) return res.status(403).json({ message: 'token ไม่ถูกต้อง' });
    req.user = user;
    next();
  });
}

// ===================== Auth Routes =====================
app.post('/register', async (req, res) => {
  const { name, email, phone, password } = req.body;
  try {
    const existingUser = await User.findOne({ email });
    if (existingUser) return res.status(400).json({ message: 'อีเมลนี้ถูกใช้ไปแล้ว' });

    const hashedPassword = await bcrypt.hash(password, 10);
    const newUser = new User({ name, email, phone, password: hashedPassword });
    await newUser.save();
    res.status(201).json({ message: 'สมัครสมาชิกสำเร็จ' });
  } catch (err) {
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการสมัครสมาชิก' });
  }
});

app.post('/login', async (req, res) => {
  const { email, password } = req.body;
  try {
    const user = await User.findOne({ email });
    if (!user) return res.status(400).json({ message: 'ไม่พบบัญชีผู้ใช้งานนี้' });

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(400).json({ message: 'รหัสผ่านไม่ถูกต้อง' });

    const token = jwt.sign({ id: user._id, email: user.email }, SECRET_KEY, { expiresIn: '1h' });
    res.json({ message: 'เข้าสู่ระบบสำเร็จ', token });
  } catch (err) {
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการเข้าสู่ระบบ' });
  }
});

// ===================== User Routes =====================
app.get('/user/me', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password');
    if (!user) return res.status(404).json({ message: 'ไม่พบผู้ใช้' });
    res.json(user);
  } catch (err) {
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการดึงข้อมูลผู้ใช้' });
  }
});

app.get('/users', async (req, res) => {
  try {
    const users = await User.find();
    res.json(users);
  } catch (err) {
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการดึงข้อมูลผู้ใช้' });
  }
});

app.get('/users/:email', async (req, res) => {
  try {
    const user = await User.findOne({ email: req.params.email });
    if (!user) return res.status(404).json({ message: 'ไม่พบผู้ใช้' });
    res.json(user);
  } catch (err) {
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการดึงข้อมูลผู้ใช้' });
  }
});

app.get('/users/id/:id', async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ message: 'ไม่พบข้อมูลผู้ใช้' });
    res.json(user);
  } catch (err) {
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการดึงข้อมูลผู้ใช้' });
  }
});

app.put('/users/:id', async (req, res) => {
  const { id } = req.params;
  const { name, email, phone, password } = req.body;
  try {
    const updateFields = { name, email, phone };
    if (password) {
      updateFields.password = await bcrypt.hash(password, 10);
    }
    const updatedUser = await User.findByIdAndUpdate(id, updateFields, { new: true });
    if (!updatedUser) return res.status(404).json({ message: 'ไม่พบข้อมูลผู้ใช้ที่ต้องการแก้ไข' });
    res.json(updatedUser);
  } catch (err) {
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการแก้ไขข้อมูลผู้ใช้' });
  }
});

// ===================== Car Routes =====================
app.get('/cars', async (req, res) => {
  try {
    const cars = await Car.find();
    res.json(cars);
  } catch (err) {
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการดึงข้อมูล' });
  }
});

app.get('/cars/:id', async (req, res) => {
  try {
    const car = await Car.findOne({ _id: parseInt(req.params.id) });
    if (!car) return res.status(404).json({ message: 'ไม่พบข้อมูลรถยนต์' });
    res.json(car);
  } catch (err) {
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการดึงข้อมูล' });
  }
});

app.post('/cars', async (req, res) => {
  const { name, brand, coverimage, color, price, detail } = req.body;
  try {
    const newId = await getNextSequenceValue('carId');
    const newCar = new Car({ _id: newId, name, brand, coverimage, color, price, detail });
    await newCar.save();
    res.status(201).json(newCar);
  } catch (err) {
    res.status(400).json({ message: 'เกิดข้อผิดพลาดในการเพิ่มข้อมูล' });
  }
});

app.put('/cars/:id', async (req, res) => {
  const { name, brand, coverimage, color, price, detail } = req.body;
  try {
    const updatedCar = await Car.findOneAndUpdate(
      { _id: parseInt(req.params.id) },
      { name, brand, coverimage, color, price, detail },
      { new: true }
    );
    if (!updatedCar) return res.status(404).json({ message: 'ไม่พบข้อมูลรถยนต์ที่ต้องการอัพเดท' });
    res.json(updatedCar);
  } catch (err) {
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการอัพเดทข้อมูล' });
  }
});

app.delete('/cars/:id', async (req, res) => {
  try {
    const deletedCar = await Car.findOneAndDelete({ _id: parseInt(req.params.id) });
    if (!deletedCar) return res.status(404).json({ message: 'ไม่พบข้อมูลรถยนต์ที่ต้องการลบ' });
    res.json({ message: 'ลบข้อมูลรถยนต์เรียบร้อยแล้ว' });
  } catch (err) {
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการลบข้อมูล' });
  }
});

// ===================== Booking Routes =====================
app.post('/booking', authenticateToken, async (req, res) => {
  const { name, brand, color, startTime, endTime, totalPrice } = req.body;

  try {
    // ตรวจสอบว่า startTime และ endTime เป็นวันที่ที่ถูกต้องหรือไม่
    if (!startTime || !endTime) {
      return res.status(400).json({ message: 'โปรดระบุเวลาเริ่มต้นและเวลาสิ้นสุด' });
    }

    // แปลงเป็น Date object ถ้าจำเป็น
    const start = new Date(startTime);
    const end = new Date(endTime);

    if (isNaN(start.getTime()) || isNaN(end.getTime())) {
      return res.status(400).json({ message: 'รูปแบบของวันเวลาที่ส่งไม่ถูกต้อง' });
    }

    const newBooking = new Booking({
      userId: req.user.id,
      name,
      brand,
      color,
      startTime: start,
      endTime: end,
      totalPrice
    });

    await newBooking.save();
    res.status(201).json({ message: 'จองรถเรียบร้อยแล้ว', booking: newBooking });
  } catch (err) {
    console.error("เกิดข้อผิดพลาดในการจองรถ:", err);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการจองรถ', error: err.message });
  }
});





app.get('/booking/my', authenticateToken, async (req, res) => {
  try {
    const bookings = await Booking.find({ userId: req.user.id }).sort({ createdAt: -1 });
    res.json(bookings);
  } catch (err) {
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการดึงประวัติการจอง' });
  }
});

app.get('/booking', async (req, res) => {
  try {
    const bookings = await Booking.find().populate('userId', 'name email');
    res.json(bookings);
  } catch (err) {
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการดึงประวัติการจองทั้งหมด' });
  }
});

app.put('/user/me', authenticateToken, async (req, res) => {
  const { name, email, phone } = req.body;

  try {
    const updateFields = {};
    if (name) updateFields.name = name;
    if (email) updateFields.email = email;
    if (phone) updateFields.phone = phone;

    const updatedUser = await User.findByIdAndUpdate(req.user.id, updateFields, { new: true });

    if (!updatedUser) return res.status(404).json({ message: 'ไม่พบข้อมูลผู้ใช้' });

    res.json(updatedUser);
  } catch (err) {
    console.error('เกิดข้อผิดพลาดในการอัปเดตผู้ใช้:', err);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการอัปเดตผู้ใช้', error: err.message });
  }
});


app.listen(5000, () => {
  console.log("เซิร์ฟเวอร์เริ่มทำงานที่ http://localhost:5000");
});