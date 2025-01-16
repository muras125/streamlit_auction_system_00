import streamlit as st
import sqlite3
from datetime import datetime, timedelta

# Database connection
conn = sqlite3.connect('auction_system.db')
c = conn.cursor()

# Create tables if they don't exist
c.execute('''CREATE TABLE IF NOT EXISTS users 
             (id INTEGER PRIMARY KEY, username TEXT, password TEXT, role TEXT)''')
c.execute('''CREATE TABLE IF NOT EXISTS auctions 
             (id INTEGER PRIMARY KEY, item_name TEXT, description TEXT, start_price REAL, end_time TEXT, seller_id INTEGER)''')
c.execute('''CREATE TABLE IF NOT EXISTS bids 
             (id INTEGER PRIMARY KEY, auction_id INTEGER, bidder_id INTEGER, bid_amount REAL)''')
conn.commit()

# Helper Functions
def register_user(username, password, role):
    c.execute("INSERT INTO users (username, password, role) VALUES (?, ?, ?)", (username, password, role))
    conn.commit()

def authenticate_user(username, password):
    c.execute("SELECT * FROM users WHERE username=? AND password=?", (username, password))
    return c.fetchone()

def create_auction(item_name, description, start_price, end_time, seller_id):
    c.execute("INSERT INTO auctions (item_name, description, start_price, end_time, seller_id) VALUES (?, ?, ?, ?, ?)", 
              (item_name, description, start_price, end_time, seller_id))
    conn.commit()

def place_bid(auction_id, bidder_id, bid_amount):
    c.execute("INSERT INTO bids (auction_id, bidder_id, bid_amount) VALUES (?, ?, ?)", 
              (auction_id, bidder_id, bid_amount))
    conn.commit()

def get_active_auctions():
    c.execute("SELECT * FROM auctions WHERE end_time > ?", (datetime.now().strftime("%Y-%m-%d %H:%M:%S"),))
    return c.fetchall()

def get_bid_status(auction_id):
    c.execute("SELECT MAX(bid_amount) FROM bids WHERE auction_id=?", (auction_id,))
    return c.fetchone()[0]

# Streamlit UI
st.set_page_config(page_title="Auction System", layout="wide")

st.title("Auction System")

# Sidebar Navigation
menu = ["Home", "Login", "Register", "Create Auction", "My Auctions"]
choice = st.sidebar.selectbox("Select a Page", menu)

if choice == "Home":
    st.header("Welcome to the Auction System")
    st.write("Browse and place bids on active auctions. Get started by logging in or registering.")
    
elif choice == "Register":
    st.header("Register as a New User")
    username = st.text_input("Username")
    password = st.text_input("Password", type="password")
    role = st.selectbox("Select Role", ["Buyer", "Seller"])
    
    if st.button("Register"):
        register_user(username, password, role)
        st.success("Registration successful! Please login.")

elif choice == "Login":
    st.header("Login")
    username = st.text_input("Username")
    password = st.text_input("Password", type="password")
    
    if st.button("Login"):
        user = authenticate_user(username, password)
        if user:
            st.success("Login successful!")
            user_id, user_name, user_password, role = user
            st.session_state.user_id = user_id
            st.session_state.username = user_name
            st.session_state.role = role
            if role == "Seller":
                st.sidebar.write(f"Welcome, {user_name} (Seller)")
            else:
                st.sidebar.write(f"Welcome, {user_name} (Buyer)")
        else:
            st.error("Invalid username or password.")
            
elif choice == "Create Auction":
    if "user_id" in st.session_state and st.session_state.role == "Seller":
        st.header("Create New Auction")
        item_name = st.text_input("Item Name")
        description = st.text_area("Item Description")
        start_price = st.number_input("Starting Price", min_value=0.0)
        auction_duration = st.slider("Auction Duration (in hours)", 1, 72)
        end_time = (datetime.now() + timedelta(hours=auction_duration)).strftime("%Y-%m-%d %H:%M:%S")
        
        if st.button("Create Auction"):
            create_auction(item_name, description, start_price, end_time, st.session_state.user_id)
            st.success("Auction created successfully!")
    else:
        st.warning("You must be logged in as a Seller to create an auction.")

elif choice == "My Auctions":
    if "user_id" in st.session_state:
        st.header("My Auctions")
        c.execute("SELECT * FROM auctions WHERE seller_id=?", (st.session_state.user_id,))
        auctions = c.fetchall()
        if auctions:
            for auction in auctions:
                st.subheader(auction[1])  # Item Name
                st.write("Description:", auction[2])
                st.write("Starting Price: $", auction[3])
                st.write("End Time:", auction[4])
                highest_bid = get_bid_status(auction[0]) or auction[3]
                st.write("Highest Bid: $", highest_bid)
        else:
            st.write("You have no active auctions.")
    else:
        st.warning("Please log in to view your auctions.")

elif choice == "Active Auctions":
    st.header("Active Auctions")
    auctions = get_active_auctions()
    if auctions:
        for auction in auctions:
            item_id, item_name, description, start_price, end_time, seller_id = auction
            st.subheader(item_name)
            st.write("Description:", description)
            st.write("Starting Price: $", start_price)
            st.write("Auction ends at:", end_time)
            highest_bid = get_bid_status(item_id) or start_price
            st.write("Highest Bid: $", highest_bid)
            
            if "user_id" in st.session_state:
                bid_amount = st.number_input("Your Bid", min_value=highest_bid, step=1.0, key=f"bid_{item_id}")
                if st.button(f"Place Bid on {item_name}", key=f"bid_button_{item_id}"):
                    place_bid(item_id, st.session_state.user_id, bid_amount)
                    st.success(f"Your bid of ${bid_amount} has been placed!")
    else:
        st.write("No active auctions at the moment.")

# Footer
st.markdown("---")
st.write("Auction System built with Streamlit. All rights reserved.")
