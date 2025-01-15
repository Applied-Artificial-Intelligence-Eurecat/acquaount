import csv
import hashlib

from flask import Flask, request, jsonify

app = Flask(__name__)


# Function to hash the password
def hash_password(password):
  return hashlib.sha256(password.encode()).hexdigest()


# Function to check if username exists
def username_exists(username):
  with open('storage/users.csv', mode='r') as file:
    reader = csv.DictReader(file)
    for row in reader:
      if row['username'] == username:
        return True
    return False


@app.route('/login', methods=['POST'])
def login():

  data = request.get_json()
  if 'username' not in data or 'password' not in data:
    return jsonify({'error': 'Missing username or password'}), 400

  username = data['username']
  password = data['password']

  if not username_exists(username):
    return jsonify({'error': 'Invalid username or password'}), 401

  with open('storage/users.csv', mode='r') as file:
    reader = csv.DictReader(file)
    for row in reader:
      if row['username'] == username:
        if row['encoded_password'] == hash_password(password):
          return jsonify({'message': 'Login successful'})
        else:
          return jsonify({'error': 'Invalid username or password'}), 401


@app.route('/register', methods=['POST'])
def register():
  data = request.get_json()
  if 'username' not in data or 'password' not in data:
    return jsonify({'error': 'Missing username or password'}), 400

  username = data['username']
  password = data['password']

  if username_exists(username):
    return jsonify({'error': 'Username already exists'}), 400

  hashed_password = hash_password(password)
  with open('storage/users.csv', mode='a', newline='') as file:
    writer = csv.writer(file)
    writer.writerow([username, hashed_password])

  return jsonify({'message': 'Registration successful'})


if __name__ == '__main__':
  app.run(debug=True, port=9091, host="0.0.0.0")
