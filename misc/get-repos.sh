ssh -p 29418 gerrit.wikimedia.org gerrit ls-projects | grep "mediawiki/extensions" | awk '{print "git clone https://gerrit.wikimedia.org/r/p/" $0}' | sh
