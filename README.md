# Bird OSPF Cost (Latency)
Automatic OSPF Cost based on Latency.

## Setup
Change config in `latency.sh` , first.  
Then, run `latency.sh` with your like the way.

Example:  
```shell
crontab -e
* * * * * /path/latency.sh > /dev/null
```
(Use crontab to run every minute.)

Have any issue? Pull request, thanks!