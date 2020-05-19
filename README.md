aviary 
------------------------------------------------------------------------------
[![Build Status](https://travis-ci.com/WeAreAVP/aviary-public.svg?branch=master)](https://travis-ci.com/WeAreAVP/aviary-public)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/4c72e65fb35047cdae145e68f6290f45)](https://www.codacy.com/gh/WeAreAVP/aviary-public?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=WeAreAVP/aviary-public&amp;utm_campaign=Badge_Grade)
[![Codacy Badge](https://api.codacy.com/project/badge/Coverage/04d2794961e745e595003ffe5aaa11f0)](https://www.codacy.com?utm_source=github.com&utm_medium=referral&utm_content=WeAreAVP/aviary&utm_campaign=Badge_Coverage)

Description
===
A cloud-based platform for publishing searchable audio and video content that pinpoints search results to the exact place where a search term is found.

Collaboration between AVP and the Fortunoff Video Archive for Holocaust Testimonies. 

Setup and Configuration
===
*  Copy .env.example to .env
    
        cp .env.example .env
    
    put correct configuration variables in the .env

*  Run Solr instance or use sunspot solr
   
        bundle exec rake sunspot:solr:start
    
    [Sunspot Solr](https://github.com/sunspot/sunspot) for more detail.
    
    if you are running a separate Solr instance then use the conf folder that is available in `solr/configsets/sunspot/conf`

* Solr Index

        rake aviary:solr_index:default
    Run this task to re-index critical/fundamental project models to be indexed by solr. Other available tasks are:

        rake aviary:solr_index:organizations
        rake aviary:solr_index:collections
        rake aviary:solr_index:collection_resources
        rake aviary:solr_index:collection_resource_files
        rake aviary:solr_index:given_class[ClassName] e.g. CollectionResource

*  Create Database
     
        bundle exec rake db:create 
    
*  Run DB Migrations
    
        bundle exec rake db:migrate
    
*  Run DB Seed
    
        bundle exec rake db:seed
        
*  Run rails server
    
        rails s

Sample Login
===

* Admin

    * email: admin@demo.com
    * password: demoadmin
    
* User     

    * email: user@demo.com
    * password: demouser   

Requirements
===

*  **OS**: CentOS 6.x
*  **Ruby**: 2.5.1
*  **Rails**: 5.1.6
*  **Nginx with Passenger**: 1.14.0
*  **MySQL**: >=5.7.x
*  **imagick**: >=6.7.2
*  **ffmpeg**: >=2.6.8
*  **git**: >=1.7.1
*  **7z**
*  **Apache Solr** >= 7.6.x
*  **Redis** 

Third Party Services
===
*  AWS S3, Cloudfront and SES
*  Wasabi Storage

Helpful Links
===
* [Setup Rails app using Passenger](https://www.digitalocean.com/community/tutorials/how-to-deploy-rails-apps-using-passenger-with-nginx-on-centos-6-5)
* [Install MySQL](https://opensourcedbms.com/dbms/installing-mysql-5-7-on-centosredhatfedora/)
* [Install ffmpeg](https://www.vultr.com/docs/how-to-install-ffmpeg-on-centos)

Contributing
===
Check out the [Contributing guide](CONTRIBUTING.md).

Code of Conduct
===
This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the  [Code of Conduct](CODE-OF-CONDUCT.md).

License
===
See the [LICENSE](LICENSE.txt) and [THIRD-PARTY-LICENSE](THIRD-PARTY-LICENSE.md) files for information on the project licenses and the licenses of incorporated third-party software.


Contributors
=== 

 *  Nouman Tayyab nouman@weareavp.com
 *  Furqan Wasi furqan@weareavp.com

  







