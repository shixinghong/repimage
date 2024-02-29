#!/bin/bash

# Copyright 2017 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Generates the a CA cert, a server key, and a server cert signed by the CA.
# reference: https://github.com/kubernetes/kubernetes/blob/master/plugin/pkg/admission/webhook/gencerts.sh
set -e

CN_BASE="repimage"

cat > server.conf << EOF
HOME			= .
RANDFILE		= $ENV::HOME/.rnd
oid_section		= new_oids
[ new_oids ]
tsa_policy1 = 1.2.3.4.1
tsa_policy2 = 1.2.3.4.5.6
tsa_policy3 = 1.2.3.4.5.7
[ ca ]
default_ca	= CA_default		# The default ca section
[ CA_default ]
dir		= /etc/pki/CA		# Where everything is kept
certs		= $dir/certs		# Where the issued certs are kept
crl_dir		= $dir/crl		# Where the issued crl are kept
database	= $dir/index.txt	# database index file.
					# several ctificates with same subject.
new_certs_dir	= $dir/newcerts		# default place for new certs.
certificate	= $dir/cacert.pem 	# The CA certificate
serial		= $dir/serial 		# The current serial number
crlnumber	= $dir/crlnumber	# the current crl number
					# must be commented out to leave a V1 CRL
crl		= $dir/crl.pem 		# The current CRL
private_key	= $dir/private/cakey.pem# The private key
RANDFILE	= $dir/private/.rand	# private random number file
x509_extensions	= usr_cert		# The extentions to add to the cert
name_opt 	= ca_default		# Subject Name options
cert_opt 	= ca_default		# Certificate field options
copy_extensions = copy
default_days	= 365			# how long to certify for
default_crl_days= 30			# how long before next CRL
default_md	= sha256		# use SHA-256 by default
preserve	= no			# keep passed DN ordering
policy		= policy_match
[ policy_match ]
countryName		= match
stateOrProvinceName	= match
organizationName	= match
organizationalUnitName	= optional
commonName		= supplied
emailAddress		= optional
[ policy_anything ]
countryName		= optional
stateOrProvinceName	= optional
localityName		= optional
organizationName	= optional
organizationalUnitName	= optional
commonName		= supplied
emailAddress		= optional
[ req ]
default_bits		= 2048
default_md		= sha256
default_keyfile 	= privkey.pem
distinguished_name	= req_distinguished_name
attributes		= req_attributes
x509_extensions	= v3_ca	# The extentions to add to the self signed cert
string_mask = utf8only
req_extensions = v3_req # The extensions to add to a certificate request
[ req_distinguished_name ]
countryName			= Country Name (2 letter code)
countryName_default		= XX
countryName_min			= 2
countryName_max			= 2
stateOrProvinceName		= State or Province Name (full name)
localityName			= Locality Name (eg, city)
localityName_default		= Default City
0.organizationName		= Organization Name (eg, company)
0.organizationName_default	= Default Company Ltd
organizationalUnitName		= Organizational Unit Name (eg, section)
commonName			= Common Name (eg, your name or your server\'s hostname)
commonName_max			= 64
emailAddress			= Email Address
emailAddress_max		= 64
[ req_attributes ]
challengePassword		= A challenge password
challengePassword_min		= 4
challengePassword_max		= 20
unstructuredName		= An optional company name
[ usr_cert ]
basicConstraints=CA:FALSE
nsComment			= "OpenSSL Generated Certificate"
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
[ v3_req ]
subjectAltName = @alt_names
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
[ alt_names ]
DNS.1 = *.default.svc
DNS.2 = *.myit.fun
DNS.3 = *.fastonetech.com
DNS.4 = localhost
DNS.5 = *.kube-system.svc
[ v3_ca ]
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always,issuer
basicConstraints = CA:true
[ crl_ext ]
authorityKeyIdentifier=keyid:always
[ proxy_cert_ext ]
basicConstraints=CA:FALSE
nsComment			= "OpenSSL Generated Certificate"
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
proxyCertInfo=critical,language:id-ppl-anyLanguage,pathlen:3,policy:foo
[ tsa ]
default_tsa = tsa_config1	# the default TSA section
[ tsa_config1 ]
dir		= ./demoCA		# TSA root directory
serial		= $dir/tsaserial	# The current serial number (mandatory)
crypto_device	= builtin		# OpenSSL engine to use for signing
signer_cert	= $dir/tsacert.pem 	# The TSA signing certificate
					# (optional)
certs		= $dir/cacert.pem	# Certificate chain to include in reply
					# (optional)
signer_key	= $dir/private/tsakey.pem # The TSA private key (optional)
default_policy	= tsa_policy1		# Policy if request did not specify it
					# (optional)
other_policies	= tsa_policy2, tsa_policy3	# acceptable policies (optional)
digests		= sha1, sha256, sha384, sha512	# Acceptable message digests (mandatory)
accuracy	= secs:1, millisecs:500, microsecs:100	# (optional)
clock_precision_digits  = 0	# number of digits after dot. (optional)
ordering		= yes	# Is ordering defined for timestamps?
				# (optional, default: no)
tsa_name		= yes	# Must the TSA name be included in the reply?
				# (optional, default: no)
ess_cert_id_chain	= no	# Must the ESS cert id chain be included?
				# (optional, default: no)
EOF

# Create a certificate authority
openssl genrsa -out caKey.pem 2048
openssl req -x509 -new -nodes -key caKey.pem -days 100000 -out caCert.pem -subj "/CN=${CN_BASE}_ca"

# Create a server certiticate
openssl genrsa -out serverKey.pem 2048
# Note the CN is the DNS name of the service of the webhook.
openssl req -new -key serverKey.pem -out server.csr -subj "/CN=${CN_BASE}.kube-system.svc" -config server.conf
openssl x509 -req -in server.csr -CA caCert.pem -CAkey caKey.pem -CAcreateserial -out serverCert.pem -days 100000 -extensions v3_req -extfile server.conf
