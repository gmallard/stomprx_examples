/*
 Copyright © 2019 Guy M. Allard

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http:www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
*/

major = "0"
minor = "0"
patch = "1"
-- mod = ""
--
-- Maybe e.g.:
mod = "PRV.1"
--
v = major"."minor"."patch
if mod <> "" then v = v || "-"mod
say "stomprx_examples version" v
return v
