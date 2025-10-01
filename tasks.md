### Task 1. - Certificate expiry date checker script
Desc - Any language, check and display expiration date of the SSL/TLS certificate for a set of Websites defined in a config file.
Expected behavior:
- [ ] Make an HTTPS request to the set of websites to retrieve the SSL/TLS certificate information.
- [ ] Parse the certificate data to extract the expiration date.
- [ ] Display the expiration date in a human-readable format.
- [ ] Create Docker container and run the script within.
Requirements:
- The script should be well-structured and maintainable, with appropriate comments and variable names for clarity.
- Handle potential errors gracefully, such as network issues or invalid certificate data.
- Ensure that the script provides a clear and readable output, making it easy to understand the certificate's expiration date.
- Consider the efficiency of the script in terms of time and resource usage.
- (opt) Define set of thresholds for warnings/errors during script execution based on the certificate expiry date
- (opt) Implement alerting mechanism for example: email, slack/teams webhook.
