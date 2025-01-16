# streamlit_auction_system_00
import streamlit as st
import sqlite3
from datetime import datetime, timedelta

# Database connection and setup
def init_db():
    conn = sqlite3.connect("auction_system.db")
    c = conn.cursor()

    # Create tables if they don't exist
    c.execute('''CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password TEXT,
        role TEXT
    )''')

    c.execute('''CREATE TABLE IF NOT EXISTS auctions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_name TEXT,
        description TEXT,
        start_price REAL,
        current_price REAL,
        bid_increment REAL,
        end_time TEXT,
        seller_id INTEGER,
        winner_id INTEGER
    )''')

    c.execute('''CREATE TABLE IF NOT EXISTS bids (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        auction_id INTEGER,
        bidder_id INTEGER,
        bid_amount REAL,
        timestamp TEXT
    )''')

    conn.commit()
    return conn

conn = init_db()

# Helper functions
def register_user(username, password, role):
    c = conn.cursor()
    try:
        c.execute("INSERT INTO users (username, password, role) VALUES (?, ?, ?)", (username, password, role))
        conn.commit()
        return True
    except sqlite3.IntegrityError:
        return False

def authenticate_user(username, password):
    c = conn.cursor()
    c.execute("SELECT * FROM users WHERE username = ? AND password = ?", (username, password))
    return c.fetchone()

def create_auction(item_name, description, start_price, bid_increment, end_time, seller_id):
    c = conn.cursor()
    c.execute("INSERT INTO auctions (item_name, description, start_price, current_price, bid_increment, end_time, seller_id) VALUES (?, ?, ?, ?, ?, ?, ?)",
              (item_name, description, start_price, start_price, bid_increment, end_time, seller_id))
    conn.commit()

def get_active_auctions():
    c = conn.cursor()
    c.execute("SELECT * FROM auctions WHERE end_time > ?", (datetime.now().strftime("%Y-%m-%d %H:%M:%S"),))
    return c.fetchall()

def place_bid(auction_id, bidder_id, bid_amount):
    c = conn.cursor()
    c.execute("SELECT current_price, bid_increment FROM auctions WHERE id = ?", (auction_id,))
    auction = c.fetchone()

    if auction and bid_amount >= auction[0] + auction[1]:
        c.execute("UPDATE auctions SET current_price = ?, winner_id = ? WHERE id = ?", (bid_amount, bidder_id, auction_id))
        c.execute("INSERT INTO bids (auction_id, bidder_id, bid_amount, timestamp) VALUES (?, ?, ?, ?)",
                  (auction_id, bidder_id, bid_amount, datetime.now().strftime("%Y-%m-%d %H:%M:%S")))
        conn.commit()
        return True
    return False

# Streamlit app
st.title("Auction System")

# Authentication
if "authenticated" not in st.session_state:
    st.session_state["authenticated"] = False

if not st.session_state["authenticated"]:
    st.sidebar.header("Login/Register")
    auth_choice = st.sidebar.radio("Choose an option", ["Login", "Register"])

    if auth_choice == "Register":
        username = st.sidebar.text_input("Username")
        password = st.sidebar.text_input("Password", type="password")
        role = st.sidebar.selectbox("Role", ["Buyer", "Seller"])
        if st.sidebar.button("Register"):
            if register_user(username, password, role):
                st.sidebar.success("Registered successfully! Please log in.")
            else:
                st.sidebar.error("Username already exists.")

    elif auth_choice == "Login":
        username = st.sidebar.text_input("Username")
        password = st.sidebar.text_input("Password", type="password")
        if st.sidebar.button("Login"):
            user = authenticate_user(username, password)
            if user:
                st.session_state["authenticated"] = True
                st.session_state["user"] = user
                st.experimental_rerun()
            else:
                st.sidebar.error("Invalid username or password.")
else:
    user = st.session_state["user"]
    st.sidebar.success(f"Logged in as {user[1]} ({user[3]})")

    if st.sidebar.button("Logout"):
        st.session_state["authenticated"] = False
        st.session_state.pop("user", None)
        st.experimental_rerun()

    # User-specific views
    if user[3] == "Seller":
        st.header("Create Auction")
        item_name = st.text_input("Item Name")
        description = st.text_area("Description")
        start_price = st.number_input("Starting Price", min_value=0.0)
        bid_increment = st.number_input("Bid Increment", min_value=0.1)
        end_time = st.date_input("End Date")
        end_time = datetime.combine(end_time, datetime.min.time()) + timedelta(hours=23, minutes=59, seconds=59)

        if st.button("Create Auction"):
            create_auction(item_name, description, start_price, bid_increment, end_time.strftime("%Y-%m-%d %H:%M:%S"), user[0])
            st.success("Auction created successfully!")

    st.header("Active Auctions")
    auctions = get_active_auctions()
    if auctions:
        for auction in auctions:
            st.subheader(auction[1])  # Item Name
            st.write("Description:", auction[2])
            st.write("Current Price:", auction[4])
            st.write("End Time:", auction[6])

            if user[3] == "Buyer":
                bid_amount = st.number_input("Your Bid Amount", min_value=auction[4] + auction[5], key=f"bid_{auction[0]}")
                if st.button("Place Bid", key=f"button_{auction[0]}"):
                    if place_bid(auction[0], user[0], bid_amount):
                        st.success("Bid placed successfully!")
                    else:
                        st.error("Your bid must be higher than the current price + increment.")
    else:
        st.write("No active auctions at the moment.")
