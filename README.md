# SSL/TLS Certificate Expiry Checker

Simple Bash script that fetches SSL/TLS certificates for a list of domains, checks OCSP revocation status, and reports expiry information with warnings.

## Features
- Concurrent checks using background jobs and `wait`
- OCSP revocation status (VALID / REVOKED / UNKNOWN / SKIPPED)
- Warnings for certificates expiring in < 30 days
- Minimal dependencies (OpenSSL, Bash, coreutils)
- Dockerized for portability

## Usage (Local)
```bash
chmod +x expirity.sh
./expirity.sh domains.txt
```
Where `domains.txt` contains one domain per line.

## Build and Run with Docker
Build the image:
```bash
docker build -t cert-checker .
```
Run with a mounted domains file:
```bash
docker run --rm -v "$PWD/success.test:/app/sites.list:ro" cert-checker
```
Or specify a different file name:
```bash
docker run --rm -v "$PWD/success.test:/data/domains.txt:ro" -w /app cert-checker ./expirity.sh /data/domains.txt
```

## Environment Variables
Currently none are required.

## Extending
Possible future improvements:
- Limit parallelism (e.g. with a job counter)
- Add JSON output option
- Add Slack / email alert integration

## Notes
- OCSP queries may be rate limited by some CAs.
- Some hosts may not provide an OCSP responder URI; these are marked as SKIPPED.
