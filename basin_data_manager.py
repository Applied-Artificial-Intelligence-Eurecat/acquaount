#!/usr/bin/env python3
"""
Combined Basin Data Manager
- Creates basin datastreams and uploads test data
- Tests and validates the data
- Can be used for both creation and verification
"""

import requests
import json
import random
import math
from datetime import datetime, timedelta

# Configuration
#BASE_URL = "http://localhost:8008/FROST-Server/v1.1"
BASE_URL = "https://monitoring.acquaount.eurecatprojects.com/wotst/FROST-Server/v1.1"
BASIN_NAME = "Cantoniera Reservoir"

def test_database_connection():
    """Test if the FROST-Server is accessible"""
    try:
        response = requests.get(f"{BASE_URL}/Things?$top=1")
        if response.status_code == 200:
            print("[OK] Database connection successful")
            return True
        else:
            print(f"[ERROR] Database connection failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"[ERROR] Database connection failed: {e}")
        return False

def create_thing_if_not_exists():
    """Create the basin thing if it doesn't exist"""
    print(f"Creating/finding thing: {BASIN_NAME}")
    
    # Check if thing already exists
    try:
        response = requests.get(f"{BASE_URL}/Things?$filter=name eq '{BASIN_NAME}'")
        if response.status_code == 200:
            data = response.json()
            if data.get('@iot.count', 0) > 0:
                thing_id = data['value'][0]['@iot.id']
                print(f"[OK] Thing already exists with ID: {thing_id}")
                return thing_id
    except Exception as e:
        print(f"[WARNING] Error checking existing thing: {e}")
    
    # Create new thing
    thing_data = {
        "name": BASIN_NAME,
        "description": f"Hydrological basin: {BASIN_NAME}",
        "properties": {
            "basin_type": "reservoir",
            "location": "Italy"
        }
    }
    
    try:
        response = requests.post(f"{BASE_URL}/Things", json=thing_data)
        if response.status_code == 201:
            thing_id = response.json()['@iot.id']
            print(f"[OK] Thing created with ID: {thing_id}")
            return thing_id
        else:
            print(f"[ERROR] Failed to create thing: {response.status_code} - {response.text}")
            return None
    except Exception as e:
        print(f"[ERROR] Error creating thing: {e}")
        return None

def create_sensor_if_not_exists():
    """Create the basin sensor if it doesn't exist"""
    sensor_name = f"{BASIN_NAME}_Sensor"
    print(f"Creating/finding sensor: {sensor_name}")
    
    # Check if sensor already exists
    try:
        response = requests.get(f"{BASE_URL}/Sensors?$filter=name eq '{sensor_name}'")
        if response.status_code == 200:
            data = response.json()
            if data.get('@iot.count', 0) > 0:
                sensor_id = data['value'][0]['@iot.id']
                print(f"[OK] Sensor already exists with ID: {sensor_id}")
                return sensor_id
    except Exception as e:
        print(f"[WARNING] Error checking existing sensor: {e}")
    
    # Create new sensor
    sensor_data = {
        "name": sensor_name,
        "description": f"Hydrological sensor for {BASIN_NAME}",
        "encodingType": "application/pdf",
        "metadata": "Basin hydrological monitoring sensor"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/Sensors", json=sensor_data)
        if response.status_code == 201:
            sensor_id = response.json()['@iot.id']
            print(f"[OK] Sensor created with ID: {sensor_id}")
            return sensor_id
        else:
            print(f"[ERROR] Failed to create sensor: {response.status_code} - {response.text}")
            return None
    except Exception as e:
        print(f"[ERROR] Error creating sensor: {e}")
        return None

def create_observed_property_if_not_exists(property_name, description, definition):
    """Create an observed property if it doesn't exist"""
    print(f"Creating/finding property: {property_name}")
    
    # Check if property already exists
    try:
        response = requests.get(f"{BASE_URL}/ObservedProperties?$filter=name eq '{property_name}'")
        print(f"Property check response status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"Property check data: {data}")
            if data.get('@iot.count', 0) > 0:
                property_id = data['value'][0]['@iot.id']
                print(f"[OK] Property already exists with ID: {property_id}")
                return property_id
            else:
                print(f"[INFO] Property '{property_name}' does not exist, will create it")
        else:
            print(f"[ERROR] Property check failed with status: {response.status_code}")
    except Exception as e:
        print(f"[WARNING] Error checking existing property: {e}")
    
    # Create new property
    property_data = {
        "name": property_name,
        "description": description,
        "definition": definition
    }
    
    try:
        response = requests.post(f"{BASE_URL}/ObservedProperties", json=property_data)
        if response.status_code == 201:
            property_id = response.json()['@iot.id']
            print(f"[OK] Property created with ID: {property_id}")
            return property_id
        else:
            print(f"[ERROR] Failed to create property: {response.status_code} - {response.text}")
            return None
    except Exception as e:
        print(f"[ERROR] Error creating property: {e}")
        return None

def create_datastream_if_not_exists(datastream_name, description, unit_name, unit_symbol, thing_id, sensor_id, property_id):
    """Create a datastream if it doesn't exist"""
    print(f"Creating/finding datastream: {datastream_name}")
    
    # Check if datastream already exists
    try:
        response = requests.get(f"{BASE_URL}/Datastreams?$filter=name eq '{datastream_name}'")
        print(f"Datastream check response status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"Datastream check data: {data}")
            if data.get('@iot.count', 0) > 0:
                datastream_id = data['value'][0]['@iot.id']
                print(f"[OK] Datastream already exists with ID: {datastream_id}")
                return datastream_id
            else:
                print(f"[INFO] Datastream '{datastream_name}' does not exist, will create it")
        else:
            print(f"[ERROR] Datastream check failed with status: {response.status_code}")
    except Exception as e:
        print(f"[WARNING] Error checking existing datastream: {e}")
    
    # Create new datastream
    datastream_data = {
        "name": datastream_name,
        "description": description,
        "observationType": "Measurement",
        "unitOfMeasurement": {
            "name": unit_name,
            "symbol": unit_symbol,
            "definition": unit_name
        },
        "Thing": {"@iot.id": thing_id},
        "Sensor": {"@iot.id": sensor_id},
        "ObservedProperty": {"@iot.id": property_id}
    }
    
    try:
        response = requests.post(f"{BASE_URL}/Datastreams", json=datastream_data)
        if response.status_code == 201:
            datastream_id = response.json()['@iot.id']
            print(f"[OK] Datastream created with ID: {datastream_id}")
            return datastream_id
        else:
            print(f"[ERROR] Failed to create datastream: {response.status_code} - {response.text}")
            return None
    except Exception as e:
        print(f"[ERROR] Error creating datastream: {e}")
        return None

def generate_realistic_hydrological_data(start_date, end_date, base_value, seasonal_pattern, variation=0.2):
    """Generate realistic hydrological data with seasonal patterns and variations"""
    observations = []
    current_date = start_date
    previous_value = base_value
    
    while current_date <= end_date:
        day_of_year = current_date.timetuple().tm_yday
        
        # Seasonal pattern
        seasonal_multiplier = 1.0 + seasonal_pattern * math.sin(2 * math.pi * (day_of_year - 80) / 365)
        
        # Add weekly patterns (weekend vs weekday variations)
        day_of_week = current_date.weekday()
        weekly_factor = 1.0
        if day_of_week >= 5:  # Weekend
            weekly_factor = 0.9  # Slightly lower on weekends
        
        # Add monthly lunar cycle influence (subtle)
        lunar_cycle = (day_of_year % 29.5) / 29.5
        lunar_factor = 1.0 + 0.05 * math.sin(2 * math.pi * lunar_cycle)
        
        # Simulate weather events (rainfall, drought periods)
        weather_event_active = random.random() < 0.1  # 10% chance of weather event
        weather_event_duration = random.randint(1, 7) if weather_event_active else 0
        weather_event_type = random.choice(['rain', 'drought']) if weather_event_active else None
        
        weather_factor = 1.0
        if weather_event_active:
            if weather_event_type == 'rain':
                weather_factor = 1.5 + random.random() * 0.5  # 1.5-2.0x increase
            else:  # drought
                weather_factor = 0.3 + random.random() * 0.4  # 0.3-0.7x decrease
        
        # Add daily temperature influence
        base_temp = 15
        temp_seasonal = 10 * math.sin(2 * math.pi * (day_of_year - 80) / 365)
        daily_temp = base_temp + temp_seasonal + random.gauss(0, 5)
        temp_factor = 1.0 + 0.02 * (daily_temp - 15) / 15
        
        # Add random daily variation (more realistic than uniform random)
        daily_variation = random.gauss(0, variation * 0.5)
        random_factor = 1 + daily_variation
        
        # Add trend/continuity
        trend_factor = 0.8
        calculated_value = base_value * seasonal_multiplier * weekly_factor * lunar_factor * weather_factor * temp_factor * random_factor
        
        value = max(0, calculated_value)
        value = min(value, base_value * 3)
        
        final_value = previous_value * trend_factor + value * (1 - trend_factor)
        previous_value = final_value
        
        observations.append({
            "result": round(final_value, 3),
            "phenomenonTime": current_date.isoformat() + "Z",
            "resultTime": current_date.isoformat() + "Z",
            "FeatureOfInterest": {
                "name": f"{BASIN_NAME}_Feature",
                "description": f"Feature of interest for {BASIN_NAME}",
                "encodingType": "application/vnd.geo+json",
                "feature": {
                    "type": "Point",
                    "coordinates": [9.0, 40.0]
                }
            }
        })
        
        current_date += timedelta(days=1)
    
    return observations

def upload_observations(datastream_id, observations):
    """Upload observations to a datastream"""
    print(f"Uploading {len(observations)} observations to datastream {datastream_id}")
    
    # Test first observation to get detailed error if any
    if observations:
        test_response = requests.post(f"{BASE_URL}/Datastreams({datastream_id})/Observations", json=observations[0])
        if test_response.status_code != 201:
            print(f"[ERROR] Failed to upload test observation: {test_response.status_code} - {test_response.text}")
            return False
    
    # Upload all observations
    success_count = 0
    for i, observation in enumerate(observations):
        try:
            response = requests.post(f"{BASE_URL}/Datastreams({datastream_id})/Observations", json=observation)
            if response.status_code == 201:
                success_count += 1
            else:
                print(f"[ERROR] Failed to upload observation {i+1}: {response.status_code} - {response.text}")
        except Exception as e:
            print(f"[ERROR] Error uploading observation {i+1}: {e}")
    
    print(f"[OK] Successfully uploaded {success_count}/{len(observations)} observations")
    return success_count == len(observations)

def create_basin_data():
    """Create all basin entities and upload data"""
    print("=" * 60)
    print("CREATING BASIN DATA")
    print("=" * 60)
    
    # Test database connection
    if not test_database_connection():
        return False
    
    # Create entities
    thing_id = create_thing_if_not_exists()
    if not thing_id:
        return False
    
    sensor_id = create_sensor_if_not_exists()
    if not sensor_id:
        return False
    
    # Define properties and their units
    properties_config = {
        "Inflow": {
            "description": "Water inflow to the basin",
            "definition": "Hydrological inflow",
            "unit_name": "Cubic meters per second",
            "unit_symbol": "M3/S",
            "base_value": 15.0,
            "seasonal_pattern": 0.3,
            "variation": 0.25
        },
        "Storage": {
            "description": "Water storage in the basin",
            "definition": "Hydrological storage",
            "unit_name": "Thousand cubic meters",
            "unit_symbol": "1000 M3",
            "base_value": 150.0,
            "seasonal_pattern": 0.2,
            "variation": 0.15
        },
        "Outflow": {
            "description": "Water outflow from the basin",
            "definition": "Hydrological outflow",
            "unit_name": "Cubic meters per second",
            "unit_symbol": "M3/S",
            "base_value": 12.0,
            "seasonal_pattern": 0.25,
            "variation": 0.20
        },
        "UrbanDemand": {
            "description": "Urban water demand for the basin",
            "definition": "Urban water consumption",
            "unit_name": "Cubic meters per second",
            "unit_symbol": "M3/month",
            "base_value": 0.0,
            "seasonal_pattern": 0.0,
            "variation": 0.0
        }
    }
    
    # Create properties and datastreams
    property_ids = {}
    datastream_ids = {}
    
    for property_name, config in properties_config.items():
        property_id = create_observed_property_if_not_exists(
            property_name, 
            config["description"], 
            config["definition"]
        )
        if not property_id:
            continue
        
        property_ids[property_name] = property_id
        
        datastream_name = f"{BASIN_NAME}_{property_name}"
        datastream_id = create_datastream_if_not_exists(
            datastream_name,
            f"Datastream for {property_name}",
            config["unit_name"],
            config["unit_symbol"],
            thing_id,
            sensor_id,
            property_id
        )
        if datastream_id:
            datastream_ids[property_name] = datastream_id
    
    # Generate and upload data
    start_date = datetime(2023, 1, 1)
    end_date = datetime(2023, 12, 31)
    
    for property_name, config in properties_config.items():
        if property_name in datastream_ids:
            print(f"\nGenerating data for {property_name}...")
            observations = generate_realistic_hydrological_data(
                start_date, 
                end_date, 
                config["base_value"], 
                config["seasonal_pattern"],
                config["variation"]
            )
            
            upload_observations(datastream_ids[property_name], observations)
    
    print("\n" + "=" * 60)
    print("BASIN DATA CREATION COMPLETED")
    print("=" * 60)
    return True

def create_urban_demand_thing():
    """Create the UrbanDemand thing and datastream"""
    print("=" * 60)
    print("CREATING URBAN DEMAND THING AND DATASTREAM")
    print("=" * 60)
    
    # Test database connection
    if not test_database_connection():
        return False
    
    # Create UrbanDemand thing
    thing_id = create_thing_if_not_exists_urban_demand()
    if not thing_id:
        return False
    
    # Create sensor for UrbanDemand
    sensor_id = create_sensor_if_not_exists_urban_demand()
    if not sensor_id:
        return False
    
    # Create UrbanDemand property
    property_id = create_observed_property_if_not_exists(
        "UrbanDemand", 
        "Urban water demand", 
        "Urban water consumption"
    )
    if not property_id:
        return False
    
    # Create UrbanDemand datastream
    datastream_name = "UrbanDemand"
    datastream_id = create_datastream_if_not_exists(
        datastream_name,
        "Datastream for UrbanDemand",
        "Cubic meters per month",
        "M3/month",
        thing_id,
        sensor_id,
        property_id
    )
    if not datastream_id:
        return False
    
    # Generate and upload data (all zeros)
    start_date = datetime(2025, 1, 1)
    end_date = datetime(2026, 3, 1)
    
    print(f"\nGenerating UrbanDemand data...")
    observations = generate_realistic_hydrological_data(
        start_date, 
        end_date, 
        0.0,  # base_value = 0
        0.0,  # seasonal_pattern = 0
        0.0   # variation = 0
    )
    
    upload_observations(datastream_id, observations)
    
    print("\n" + "=" * 60)
    print("URBAN DEMAND THING AND DATASTREAM CREATION COMPLETED")
    print("=" * 60)
    return True

def create_thing_if_not_exists_urban_demand():
    """Create the UrbanDemand thing if it doesn't exist"""
    print(f"Creating/finding thing: UrbanDemand")
    
    # Check if thing already exists
    try:
        response = requests.get(f"{BASE_URL}/Things?$filter=name eq 'UrbanDemand'")
        if response.status_code == 200:
            data = response.json()
            if data.get('@iot.count', 0) > 0:
                thing_id = data['value'][0]['@iot.id']
                print(f"[OK] Thing already exists with ID: {thing_id}")
                return thing_id
    except Exception as e:
        print(f"[WARNING] Error checking existing thing: {e}")
    
    # Create new thing
    thing_data = {
        "name": "UrbanDemand",
        "description": "Urban Water Demand Thing",
        "properties": {
            "pilot": "ACQUAOUNT"
        }
    }
    
    try:
        response = requests.post(f"{BASE_URL}/Things", json=thing_data)
        if response.status_code == 201:
            thing_id = response.json()['@iot.id']
            print(f"[OK] Thing created with ID: {thing_id}")
            return thing_id
        else:
            print(f"[ERROR] Failed to create thing: {response.status_code} - {response.text}")
            return None
    except Exception as e:
        print(f"[ERROR] Error creating thing: {e}")
        return None

def create_sensor_if_not_exists_urban_demand():
    """Create the UrbanDemand sensor if it doesn't exist"""
    print(f"Creating/finding sensor for UrbanDemand")
    
    # Check if sensor already exists
    try:
        response = requests.get(f"{BASE_URL}/Sensors?$filter=name eq 'UrbanDemand_Sensor'")
        if response.status_code == 200:
            data = response.json()
            if data.get('@iot.count', 0) > 0:
                sensor_id = data['value'][0]['@iot.id']
                print(f"[OK] Sensor already exists with ID: {sensor_id}")
                return sensor_id
    except Exception as e:
        print(f"[WARNING] Error checking existing sensor: {e}")
    
    # Create new sensor
    sensor_data = {
        "name": "UrbanDemand_Sensor",
        "description": "Sensor for urban water demand measurements",
        "encodingType": "application/pdf",
        "metadata": "Urban demand sensor metadata"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/Sensors", json=sensor_data)
        if response.status_code == 201:
            sensor_id = response.json()['@iot.id']
            print(f"[OK] Sensor created with ID: {sensor_id}")
            return sensor_id
        else:
            print(f"[ERROR] Failed to create sensor: {response.status_code} - {response.text}")
            return None
    except Exception as e:
        print(f"[ERROR] Error creating sensor: {e}")
        return None

def test_basin_data():
    """Test and validate the basin data"""
    print("=" * 60)
    print("TESTING BASIN DATA")
    print("=" * 60)
    
    print(f"Testing basin data for: {BASIN_NAME}")
    print(f"Database URL: {BASE_URL}")
    print("-" * 50)
    
    # 1. Check if the thing exists
    print("1. Checking if thing exists...")
    response = requests.get(f"{BASE_URL}/Things?$filter=name eq '{BASIN_NAME}'")
    if response.status_code == 200:
        data = response.json()
        if data.get('@iot.count', 0) > 0:
            thing = data['value'][0]
            print(f"[OK] Thing found: {thing['name']} (ID: {thing['@iot.id']})")
        else:
            print("[ERROR] Thing not found")
            return False
    else:
        print(f"[ERROR] Error getting thing: {response.status_code}")
        return False
    
    # 2. Check datastreams and their date ranges
    print("\n2. Checking datastreams and date ranges...")
    datastreams = ["Inflow", "Storage", "Outflow"]
    for ds_type in datastreams:
        ds_name = f"{BASIN_NAME}_{ds_type}"
        response = requests.get(f"{BASE_URL}/Datastreams?$filter=name eq '{ds_name}'")
        if response.status_code == 200:
            data = response.json()
            if data.get('@iot.count', 0) > 0:
                ds = data['value'][0]
                print(f"[OK] Datastream found: {ds['name']} (ID: {ds['@iot.id']})")
                
                # Check observations count and date range
                obs_response = requests.get(f"{BASE_URL}/Datastreams({ds['@iot.id']})/Observations?$orderby=phenomenonTime asc&$top=1")
                if obs_response.status_code == 200:
                    obs_data = obs_response.json()
                    count = obs_data.get('@iot.count', 0)
                    print(f"   [INFO] Total observations count: {count}")
                    
                    if count > 0:
                        # Get first and last observation
                        first_obs = obs_data['value'][0]
                        
                        # Get last observation
                        last_obs_response = requests.get(f"{BASE_URL}/Datastreams({ds['@iot.id']})/Observations?$orderby=phenomenonTime desc&$top=1")
                        if last_obs_response.status_code == 200:
                            last_obs_data = last_obs_response.json()
                            last_obs = last_obs_data['value'][0]
                            
                            print(f"   [INFO] Date range: {first_obs['phenomenonTime']} to {last_obs['phenomenonTime']}")
                            print(f"   [INFO] First value: {first_obs['result']}")
                            print(f"   [INFO] Last value: {last_obs['result']}")
                else:
                    print(f"   [ERROR] Error getting observations: {obs_response.status_code}")
            else:
                print(f"[ERROR] Datastream not found: {ds_name}")
        else:
            print(f"[ERROR] Error getting datastream {ds_name}: {response.status_code}")
    
    # 3. Test with the actual data date range
    print("\n3. Testing with actual data date range...")
    
    # Use the actual date range from the data (2023-01-01 to 2023-12-31)
    start_time = "2023-01-01T00:00:00Z"
    end_time = "2023-12-31T23:59:59Z"
    
    print(f"   Date range: {start_time} to {end_time}")
    
    for ds_type in datastreams:
        ds_name = f"{BASIN_NAME}_{ds_type}"
        print(f"\n   Testing {ds_name}...")
        
        # Get datastream ID first
        ds_response = requests.get(f"{BASE_URL}/Datastreams?$filter=name eq '{ds_name}'")
        if ds_response.status_code == 200:
            ds_data = ds_response.json()
            if ds_data.get('@iot.count', 0) > 0:
                ds_id = ds_data['value'][0]['@iot.id']
                
                # Test the exact query
                query_url = f"{BASE_URL}/Datastreams({ds_id})/Observations?$filter=phenomenonTime ge {start_time} and phenomenonTime le {end_time}&$top=10"
                print(f"   Query: {query_url}")
                
                obs_response = requests.get(query_url)
                if obs_response.status_code == 200:
                    obs_data = obs_response.json()
                    count = obs_data.get('@iot.count', 0)
                    print(f"   [OK] Found {count} observations in date range")
                    
                    if count > 0:
                        print(f"   [INFO] Sample observations:")
                        for i, obs in enumerate(obs_data['value'][:3]):
                            print(f"      {i+1}. {obs['phenomenonTime']}: {obs['result']}")
                else:
                    print(f"   [ERROR] Error: {obs_response.status_code} - {obs_response.text}")
            else:
                print(f"   [ERROR] Datastream not found")
        else:
            print(f"   [ERROR] Error getting datastream: {ds_response.status_code}")
    
    print("\n" + "=" * 60)
    print("BASIN DATA TESTING COMPLETED")
    print("=" * 60)
    return True

def main():
    """Main function to run the basin data manager"""
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: python basin_data_manager.py [create|test|both]")
        print("  create - Create basin datastreams and upload data")
        print("  test   - Test and validate existing data")
        print("  both   - Create data and then test it")
        return
    
    command = sys.argv[1].lower()
    
    if command == "create":
        create_basin_data()
    elif command == "test":
        test_basin_data()
    elif command == "both":
        if create_basin_data():
            print("\n" + "=" * 60)
            test_basin_data()
    elif command == "urban":
        create_urban_demand_thing()
    else:
        print("Invalid command. Use: create, test, both, or urban")

if __name__ == "__main__":
    main() 