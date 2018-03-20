# Scoring
Scoring algorithm for ranking customers

The score of a company consists of three parts
  * Norm -- this part is always present when calculating the score
  * Additional SC -- this part is only accounted for within the score if it is known to SC (not known, means a penalty in score)
  * Additional trade -- this part is only accounted for within the score if it is known to SC
  
Within each part of the score several elements are accounted for.
  * Norm -- takes into account the years in business of a company, whether a company has a social media account and a website, and whether
  the company is a member of an industry association
  * Additional SC -- takes into account the verification level a company has within our platform, the peer & trade reviews of a company
  and the trade experience
  * Additional trade -- takes into account the number of open claims and the cancelled orders
