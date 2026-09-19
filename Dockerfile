FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Copy requirements file and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code
COPY requester.py .

# Run the script
CMD ["python", "requester.py"]

