# test-round-trip
This repo is to test the round trip time between East Asia and UK South with 2 App Services, one in UK South and the other in East Asia.

By running the bash script, the following Azure resources will be created
1. 1 App Service Plan in UK South and 1 App Service Plan in East Asia
2. 1 App Service in UK South and 1 App Service in East Asia
3. 1 VNet in UK South and 1 VNet in East Asia
4. 1 Container Registry in EastAsia
5. Network Peering between the 2 Vnets
The UK South App is a simple flask service that serves HTTP requests.
The East Asia App will send requests to UK South App every 30 seconds, and print the round trip time.

## To run the script
`./deploy-peering-apps.sh`

## Performance analysis
The round trip time summary is given in the `analysis` folder. It contains the round trip time outputs.
1. The `round_trip_comparison.log` file contains the round trip time outputs from HK App Service to UK App Service and from HK App Service to UK VM. The outputs are generated from another App Service for testing round trip time.
2. The `round_trip_comparison.log` file contains the round trip time outputs from HK App Service to UK App Service. The outputs are generated from App Service created by this repo.

To run the analysis script
```
cd analysis
python3 summary.py
```