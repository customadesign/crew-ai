# DigitalOcean Deployment Guide for CrewAI

## Prerequisites
- DigitalOcean account
- Domain name (optional)
- API keys (OpenAI, Serper, etc.)

## Step 1: Create a DigitalOcean Droplet

1. Log in to DigitalOcean
2. Click "Create" → "Droplets"
3. Choose configuration:
   - **Image**: Ubuntu 22.04 LTS
   - **Plan**: Basic
   - **CPU options**: Regular (4GB RAM minimum recommended)
   - **Datacenter**: Choose nearest to your location
   - **Authentication**: SSH keys (recommended) or password
   - **Hostname**: `crewai-server`

## Step 2: Connect to Your Droplet

```bash
ssh root@your_droplet_ip
```

## Step 3: Initial Server Setup

```bash
# Update system packages
apt update && apt upgrade -y

# Create a non-root user
adduser crewai
usermod -aG sudo crewai

# Set up firewall
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable
```

## Step 4: Install Docker and Docker Compose

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Add user to docker group
usermod -aG docker crewai

# Install Docker Compose
apt install docker-compose -y

# Verify installation
docker --version
docker-compose --version
```

## Step 5: Deploy Your CrewAI Application

```bash
# Switch to crewai user
su - crewai

# Create project directory
mkdir -p ~/crewai-app
cd ~/crewai-app

# Clone your repository or upload files
# Option 1: Using git
git clone https://github.com/yourusername/your-crewai-repo.git .

# Option 2: Using SCP from local machine
# scp -r /path/to/your/crewai/* crewai@your_droplet_ip:~/crewai-app/

# Create .env file
nano .env
```

Add to .env:
```
OPENAI_API_KEY=your_openai_key_here
SERPER_API_KEY=your_serper_key_here
# Add other environment variables
```

## Step 6: Build and Run

```bash
# Build the Docker image
docker-compose build

# Run the application
docker-compose up -d

# Check logs
docker-compose logs -f
```

## Step 7: Set Up Nginx as Reverse Proxy (Optional)

```bash
# Install Nginx
sudo apt install nginx -y

# Create Nginx configuration
sudo nano /etc/nginx/sites-available/crewai
```

Add configuration:
```nginx
server {
    listen 80;
    server_name your_domain.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
# Enable the site
sudo ln -s /etc/nginx/sites-available/crewai /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

## Step 8: SSL Certificate with Let's Encrypt (Optional)

```bash
# Install Certbot
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot

# Get SSL certificate
sudo certbot --nginx -d your_domain.com
```

## Step 9: Set Up Monitoring

```bash
# Install monitoring tools
sudo apt install htop -y

# Set up Docker container auto-restart
# Already configured in docker-compose.yml with restart: unless-stopped
```

## Step 10: Backup Strategy

Create a backup script:
```bash
nano ~/backup.sh
```

Add:
```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
docker-compose exec crewai tar czf - /app/data > ~/backups/crewai_backup_$DATE.tar.gz
```

Make it executable:
```bash
chmod +x ~/backup.sh
mkdir ~/backups

# Add to crontab for daily backups
crontab -e
# Add: 0 2 * * * /home/crewai/backup.sh
```

## Maintenance Commands

```bash
# View logs
docker-compose logs -f

# Restart application
docker-compose restart

# Update application
git pull
docker-compose build
docker-compose up -d

# Check resource usage
htop
docker stats
```

## Troubleshooting

1. **Port issues**: Ensure firewall allows your application port
2. **Memory issues**: Upgrade droplet if needed
3. **API key errors**: Check .env file permissions and values
4. **Docker permission denied**: Ensure user is in docker group

## Security Best Practices

1. Use SSH keys instead of passwords
2. Keep system updated: `apt update && apt upgrade`
3. Use environment variables for sensitive data
4. Enable UFW firewall
5. Regular backups
6. Monitor logs for suspicious activity