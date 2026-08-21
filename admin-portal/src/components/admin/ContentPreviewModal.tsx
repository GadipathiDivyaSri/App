import React from 'react';
import { Modal } from '../common/Modal';
import { Button } from '../common/Button';
import { CareerPath, CareerMilestone } from '../../types';
import { ContentStatusBadge } from './ContentStatusBadge';
import {
  Compass,
  Smartphone,
} from 'lucide-react';

interface CareerPreviewData {
  path: CareerPath;
  milestones: CareerMilestone[];
}

interface ContentPreviewModalProps {
  isOpen: boolean;
  onClose: () => void;
  type?: 'career';
  careerData?: CareerPreviewData | null;
}

export const ContentPreviewModal: React.FC<ContentPreviewModalProps> = ({
  isOpen,
  onClose,
  careerData,
}) => {
  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={`App Preview: ${careerData?.path?.name || 'Career Path'}`}
      maxWidth="max-w-2xl"
    >
      <div className="space-y-4">
        {/* Mobile Device Mock Framing Header */}
        <div className="flex items-center justify-between px-3 py-2 bg-zinc-900 text-white rounded-t-xl text-xs font-medium">
          <div className="flex items-center gap-2">
            <Smartphone className="w-4 h-4 text-emerald-400" />
            <span className="font-semibold tracking-wide">WrindhaOS Mobile App Simulation</span>
          </div>
          <div className="text-[11px] text-zinc-400">Student Live Experience</div>
        </div>

        {/* ==========================================
            CAREER PREVIEW
        ========================================== */}
        {careerData && (
          <div className="bg-zinc-50 rounded-b-xl border border-zinc-200/90 p-5 space-y-5">
            {/* Career Path Header */}
            <div className="bg-white rounded-xl p-4 shadow-xs border border-zinc-200/80 space-y-3">
              <div className="flex items-start justify-between gap-3">
                <div className="flex items-center gap-3">
                  <div className="w-11 h-11 rounded-xl bg-emerald-50 border border-emerald-100 flex items-center justify-center text-emerald-700 font-bold">
                    <Compass className="w-5 h-5" />
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded bg-zinc-100 text-zinc-700">
                        {careerData.path.category?.name || 'Career'}
                      </span>
                      <ContentStatusBadge status={careerData.path.status} size="sm" />
                    </div>
                    <h3 className="text-base font-bold text-zinc-900 mt-1">
                      {careerData.path.name}
                    </h3>
                  </div>
                </div>
              </div>

              {careerData.path.description && (
                <p className="text-xs text-zinc-600 leading-relaxed">
                  {careerData.path.description}
                </p>
              )}

              {/* Skills pills */}
              {careerData.path.skills && careerData.path.skills.length > 0 && (
                <div className="space-y-1.5 pt-2 border-t border-zinc-100">
                  <div className="text-[11px] font-semibold text-zinc-500 uppercase tracking-wider">
                    Core Skills Acquired
                  </div>
                  <div className="flex flex-wrap gap-1.5">
                    {careerData.path.skills.map((skill, sIdx) => (
                      <span
                        key={sIdx}
                        className="text-xs px-2.5 py-0.5 bg-emerald-50 text-emerald-800 rounded-md border border-emerald-200 font-medium"
                      >
                        {skill}
                      </span>
                    ))}
                  </div>
                </div>
              )}
            </div>

            {/* Milestones Roadmap */}
            <div className="space-y-3">
              <div className="flex items-center justify-between px-1">
                <span className="text-xs font-bold uppercase tracking-wider text-zinc-500">
                  Career Roadmap & Milestone Steps ({careerData.milestones.length})
                </span>
                <span className="text-[11px] text-zinc-400">Step-by-step Execution</span>
              </div>

              {careerData.milestones.length === 0 ? (
                <div className="p-6 text-center text-xs text-zinc-400 bg-white rounded-xl border border-zinc-200">
                  No milestones configured for this career path yet.
                </div>
              ) : (
                <div className="relative pl-6 space-y-4 before:absolute before:left-2.5 before:top-3 before:bottom-3 before:w-0.5 before:bg-emerald-200">
                  {careerData.milestones.map((ms, idx) => (
                    <div
                      key={ms.id}
                      className="relative bg-white rounded-xl p-3.5 border border-zinc-200 shadow-2xs space-y-1.5"
                    >
                      {/* Timeline dot */}
                      <div className="absolute -left-6 top-4 w-4 h-4 rounded-full bg-emerald-600 border-2 border-white shadow-xs" />

                      <div className="flex items-start justify-between gap-2">
                        <div className="flex items-center gap-2">
                          <span className="w-5 h-5 rounded-full bg-emerald-100 text-emerald-800 text-[10px] font-bold flex items-center justify-center shrink-0">
                            {idx + 1}
                          </span>
                          <h4 className="text-xs font-bold text-zinc-900">{ms.title}</h4>
                        </div>
                        <ContentStatusBadge status={ms.status} size="sm" />
                      </div>

                      {ms.description && (
                        <p className="text-[11px] text-zinc-600 leading-relaxed pl-7">
                          {ms.description}
                        </p>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        )}

        <div className="flex justify-end pt-2">
          <Button variant="outline" size="sm" onClick={onClose}>
            Close Preview
          </Button>
        </div>
      </div>
    </Modal>
  );
};
