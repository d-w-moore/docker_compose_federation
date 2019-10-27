# Federation test setup

   - ```
     docker-compose up
     ```

   - for each container:
     ```
     docker exec -it CONTAINER_NAME  bash
     (inside container) /install_irods.sh && /setup_federation.sh
     
     ```
