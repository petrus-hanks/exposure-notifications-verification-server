# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

VETTERS = "asmdecl,assign,atomic,bools,buildtag,cgocall,composites,copylocks,errorsas,httpresponse,loopclosure,lostcancel,nilfunc,printf,shift,stdmethods,structtag,tests,unmarshal,unreachable,unsafeptr,unusedresult"
GOFMT_FILES = $(shell go list -f '{{.Dir}}' ./...)
HTML_FILES = $(shell find . -name \*.html)
GO_FILES = $(shell find . -name \*.go)
MD_FILES = $(shell find . -name \*.md)

fmtcheck:
	@command -v goimports > /dev/null 2>&1 || go get golang.org/x/tools/cmd/goimports
	@CHANGES="$$(goimports -d $(GOFMT_FILES))"; \
		if [ -n "$${CHANGES}" ]; then \
			echo "Unformatted (run goimports -w .):\n\n$${CHANGES}\n\n"; \
			exit 1; \
		fi
	@# Annoyingly, goimports does not support the simplify flag.
	@CHANGES="$$(gofmt -s -d $(GOFMT_FILES))"; \
		if [ -n "$${CHANGES}" ]; then \
			echo "Unformatted (run gofmt -s -w .):\n\n$${CHANGES}\n\n"; \
			exit 1; \
		fi
.PHONY: fmtcheck

tabcheck:
	@CHANGES="$$(awk '/\t/ {print FILENAME,FNR}' $(HTML_FILES))"; \
		if [ -n "$${CHANGES}" ]; then \
			echo "$${CHANGES}\n\n"; \
			exit 1; \
		fi
.PHONY: tabcheck

bodyclose:
	@command -v bodyclose > /dev/null 2>&1 || go get github.com/timakin/bodyclose
	@go vet -vettool=$$(which bodyclose) ./...
.PHONY: bodyclose

spellcheck:
	@command -v misspell > /dev/null 2>&1 || go get github.com/client9/misspell/cmd/misspell
	@misspell -locale="US" -error -source="text" $(GO_FILES) $(HTML_FILES) $(MD_FILES)
.PHONY: spellcheck

staticcheck:
	@command -v staticcheck > /dev/null 2>&1 || go get honnef.co/go/tools/cmd/staticcheck
	@staticcheck -checks="all,-S1023" -tests $(GOFMT_FILES)
.PHONY: staticcheck

zapcheck:
	@command -v zapw > /dev/null 2>&1 || GO111MODULE=off go get github.com/sethvargo/zapw/cmd/zapw
	@zapw ./...

test:
	@go test \
		-count=1 \
		-short \
		-timeout=5m \
		-vet="${VETTERS}" \
		./...
.PHONY: test

test-acc:
	@go test \
		-count=1 \
		-race \
		-timeout=10m \
		-vet="${VETTERS}" \
		./... \
		-coverprofile=coverage.out
.PHONY: test-acc

test-coverage:
	@go tool cover -func ./coverage.out | grep total
.PHONY: test-coverage
