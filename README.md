mason
=====

CodeCombat uses these scripts to do deployments.

The server prepares the production code on local machines and, in parallel, deploys the code onto production servers.
This allows the scripts to deploy 1 server or 500 servers with the same speed. When the new code is running, the script will
wait for automated or manual confirmation that there are no problems with the deployed code. Once the script receives confirmation, it will
place the new servers on the load balancer, and once the ELB confirms the new servers are healthy, it will take the old servers off.
Once the connection drain period ends, the old instances will be terminated.

##Contributions
If you want to contribute, fantastic! The best way to collaborate
would be to either file issues or [email me](mailto:michael@codecombat.com).

##Things to do

1.  Make it easier for people to adapt these scripts for different products.
1. Fix log output during parallel server configurations
1. Write tests
1. Refactor to make the code prettier
1. Add multi-region deployment support with Route53.
1. Integrate automation of MongoDB replica set maintenance

##License

The MIT License (MIT)

Copyright (c) 2014 CodeCombat, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
