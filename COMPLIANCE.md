# ocaml-dns and µdns compliance to RFCs (NEEDS TO BE UPDATED ASAP)

## Introduction

The goal of this project is to check both ocaml-dns and µdns on their compliance to RFC specifications. There are many RFCs defining DNS standards : this attempt will probably be non-exhaustive.
For now, only non-compliance will be written as the list should be shorter.
Most of those non-compliance features have been found using fuzzing tools such as Crowbar or by reading the code.

## ocaml-dns compliance

* RFC2181, Section 8 
* RFC2181, Section 11. - Label length < 63 : OK
* RFC2181, Section 11. - Total length < 255 : OK if the PR is merged


## µDNS compliance

* RFC2181, Section 8. - TTL is set on the less significant 31 bits on the 32 bit TTL field, with the MSB set to zero. If a TTL has the MSB set, the entire value should be considered as zero : Not done, but may still be correct (raises an error)
* RFC2181, Section 11. - Label length < 63 : OK
* RFC2181, Section 11 - Total length < 255 : OK
* RFC3597, Section 5. - Parsing an unknown RR type number returns TYPE[number] : NOT DONE (raises an error)
* RFC3597, Section 5. - Parsing an unknown RR class number returns CLASS[number] : NOT DONE (raises an error)

