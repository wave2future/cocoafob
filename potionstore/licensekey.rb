#!/usr/bin/env ruby
#
# Modify this file and put in your own license key generator
#

require "openssl"
require "rubygems"
require "base32"

def make_license_source(product_code, name)
  product_code + "," + name
end

def make_license(product_code, name, copies)
  sign_dss1 = OpenSSL::Digest::DSS1.new
  priv = OpenSSL::PKey::DSA.new(File.read("dsapriv512.pem"))
  b32 = Base32.encode(priv.sign(sign_dss1, make_license_source(product_code, name)))
  # Replace Os with 8s and Is with 9s
  # See http://members.shaw.ca/akochoi-old/blog/2004/11-07/index.html
  b32.gsub!(/O/, '8')
  b32.gsub!(/I/, '9')
  # assume length of 80 chars; chop off trailing padding
  b32.delete("=").scan(/.{1,5}/).join("-")
end

def verify_license(product_code, name, copies, lic)
  verify_dss1 = OpenSSL::Digest::DSS1.new
  pub = OpenSSL::PKey::DSA.new(File.read("dsapub512.pem"))
  # pad at the end with equals sign to the length of 80 chars
  lic.delete!("-")
  lic.gsub!(/9/, 'I')
  lic.gsub!(/8/, 'O')
  # padded length has to divide by 8
  padded_length = lic.length%8 ? (lic.length/8 + 1)*8 : lic.length
  padded = lic + "=" * (padded_length-lic.length)
  pub.verify(verify_dss1, Base32.decode(padded), make_license_source(product_code, name))
end

# Simple command line test
if __FILE__ == $0
  require "test/unit"
  class TestPxLic < Test::Unit::TestCase
    def test_make_license
      1000.times do
        lic = make_license('product', 'User Name', 10)
        puts lic
        assert verify_license('product', 'User Name', 10, lic), "Failed with #{lic}"
      end
    end
  end
end
