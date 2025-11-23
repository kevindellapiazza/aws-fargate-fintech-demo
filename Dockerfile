# Use a lightweight base image to reduce cold start time and ECR storage costs
FROM python:3.9-slim

# Set working directory to keep the container filesystem clean
WORKDIR /code

# CACHE OPTIMIZATION: Copy only requirements first.
# This allows Docker to cache the installed dependencies layer
# and skip re-installation if only the application code changes.
COPY ./app/requirements.txt /code/requirements.txt

# Install dependencies. 
# --no-cache-dir: reduces image size by not storing source files
RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt

# Copy the actual application code
COPY ./app /code/app

# Add /code to PYTHONPATH so imports work correctly
ENV PYTHONPATH=/code

# Start the Uvicorn server.
# Host 0.0.0.0 is mandatory for container networking.
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "80"]