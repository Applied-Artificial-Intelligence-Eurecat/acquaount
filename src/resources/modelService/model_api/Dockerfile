FROM python:3.10

WORKDIR /app

# Install system dependencies (distutils is included by default with this image)
RUN apt-get -y update \
    && apt-get -y install gfortran

COPY requirements.txt .

# Install the dependencies
RUN pip install --upgrade pip \
    && pip install --upgrade -r requirements.txt

# Copy the FastAPI application code
COPY . .

# Expose the port that the FastAPI app runs on
EXPOSE 8000

# Command to run the FastAPI application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
