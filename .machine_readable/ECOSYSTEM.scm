;; SPDX-License-Identifier: PMPL-1.0-or-later
;; ECOSYSTEM.scm for SoftwareSovereign.jl
;; Media Type: application/vnd.ecosystem+scm

(ecosystem
  (version "1.0")
  (name "SoftwareSovereign.jl")
  (type "julia-package")
  (purpose "Software policy auditing and license compliance framework")
  (position-in-ecosystem
    (domain "governance")
    (role "License compliance auditing and software sovereignty policy enforcement")
    (maturity "skeleton"))
  (related-projects
    ((name . "hyperpolymath ecosystem")
     (relationship . part-of)
     (nature . "Julia packages for interdisciplinary computing"))))
